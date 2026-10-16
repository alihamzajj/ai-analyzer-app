// Deno HTTP server for analyse-chat Supabase Edge Function
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.38.4";
import { corsHeaders } from "../_shared/cors.ts";
import { AnalysisRequestBody, AnalysisResponsePayload } from "../_shared/types.ts";
import { buildSystemPrompt, buildUserPrompt } from "../_shared/prompts.ts";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL") ?? "";
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
const AI_API_KEY = Deno.env.get("GEMINI_API_KEY") || Deno.env.get("OPENAI_API_KEY") || "";
// Optional override, e.g. `supabase secrets set GEMINI_MODEL=gemini-2.5-flash`.
const GEMINI_MODEL_OVERRIDE = Deno.env.get("GEMINI_MODEL") ?? "";

// Fair-use limits. Override with secrets USER_DAILY_LIMIT / USER_WEEKLY_LIMIT / GLOBAL_DAILY_LIMIT.
const DAY_MS = 24 * 60 * 60 * 1000;
const USER_DAILY_LIMIT = Number(Deno.env.get("USER_DAILY_LIMIT") ?? 3);
const USER_WEEKLY_LIMIT = Number(Deno.env.get("USER_WEEKLY_LIMIT") ?? 10);
// Keeps the shared free Gemini quota from ever being emptied.
const GLOBAL_DAILY_LIMIT = Number(Deno.env.get("GLOBAL_DAILY_LIMIT") ?? 300);

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);
  let reservedUsageId: string | null = null;
  // A failed analysis shouldn't use up one of the user's reports.
  const releaseSlot = async () => {
    if (reservedUsageId) await supabase.from("analysis_usage").delete().eq("id", reservedUsageId);
    reservedUsageId = null;
  };

  try {

    const json = (status: number, payload: unknown) =>
      new Response(JSON.stringify(payload), {
        status,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });

    // 1. Require a real signed-in user. The app signs in anonymously at startup,
    //    so every install has its own Supabase user that can't be faked.
    const token = (req.headers.get("Authorization") ?? "").replace("Bearer ", "").trim();
    const { data: authData } = token ? await supabase.auth.getUser(token) : { data: { user: null } };
    const user = authData?.user;
    if (!user) {
      return json(401, { error: "AUTH_REQUIRED", message: "Please update the app and try again." });
    }
    const userId = user.id;

    // 2. Parse request body
    const body: AnalysisRequestBody = await req.json();

    if (!body.compact_messages || body.compact_messages.length === 0) {
      return json(400, { error: "Missing compact_messages in request." });
    }

    // 3. Fair-use limits, counted in the database (analysis_usage).
    const now = Date.now();
    const since = (ms: number) => new Date(now - ms).toISOString();
    const countSince = async (iso: string, onlyThisUser: boolean) => {
      let q = supabase.from("analysis_usage").select("id", { count: "exact", head: true }).gte("created_at", iso);
      if (onlyThisUser) q = q.eq("user_id", userId);
      const { count } = await q;
      return count ?? 0;
    };

    const [userDay, userWeek, everyoneDay] = await Promise.all([
      countSince(since(DAY_MS), true),
      countSince(since(7 * DAY_MS), true),
      countSince(since(DAY_MS), false),
    ]);

    if (everyoneDay >= GLOBAL_DAILY_LIMIT) {
      return json(429, { error: "AI_BUSY", message: "Lots of people are checking vibes today. Please try again tomorrow." });
    }
    if (userDay >= USER_DAILY_LIMIT) {
      return json(429, { error: "DAILY_LIMIT", message: `You can make ${USER_DAILY_LIMIT} AI reports per day. Come back tomorrow!` });
    }
    if (userWeek >= USER_WEEKLY_LIMIT) {
      return json(429, { error: "WEEKLY_LIMIT", message: `You've used all ${USER_WEEKLY_LIMIT} AI reports for this week.` });
    }

    // Reserve the slot before calling the AI, so rapid repeat taps are counted too.
    const { data: usageRow } = await supabase
      .from("analysis_usage")
      .insert({ user_id: userId, analysis_type: body.relationship_type ?? "unknown" })
      .select("id")
      .single();
    reservedUsageId = usageRow?.id ?? null;

    // 4. Load active model configuration from database
    const { data: modelConfigs } = await supabase
      .from("model_config")
      .select("*")
      .eq("is_active", true)
      .limit(1);

    const activeModel = modelConfigs && modelConfigs.length > 0
      ? modelConfigs[0]
      : { provider: "gemini", model_id: "gemini-flash-latest", input_cost_per_m: 0.075, output_cost_per_m: 0.30 };
    if (GEMINI_MODEL_OVERRIDE) activeModel.model_id = GEMINI_MODEL_OVERRIDE;

    // 5. Build prompts
    const systemPrompt = buildSystemPrompt(body);
    const userPrompt = buildUserPrompt(body);

    // Set of valid message IDs passed in this request
    const validMessageIds = new Set(body.compact_messages.map((m) => m.id));

    // 6. Call AI Provider
    let rawJsonResponse = "";
    let inputTokens = Math.ceil((systemPrompt.length + userPrompt.length) / 4);
    let outputTokens = 1200;

    if (AI_API_KEY) {
      const requestPayload = JSON.stringify({
        contents: [
          { role: "user", parts: [{ text: `${systemPrompt}\n\n${userPrompt}` }] }
        ],
        generationConfig: {
          responseMimeType: "application/json",
          temperature: 0.7,
          // Room for 6-10 cards plus the model's internal reasoning tokens.
          maxOutputTokens: 8192,
        },
      });

      // Google retires model names over time; fall through to the always-current aliases.
      const candidateModels = [...new Set([activeModel.model_id, "gemini-flash-latest", "gemini-flash-lite-latest"])];
      let aiResponse: Response | null = null;
      for (const modelId of candidateModels) {
        aiResponse = await fetch(
          `https://generativelanguage.googleapis.com/v1beta/models/${modelId}:generateContent?key=${AI_API_KEY}`,
          { method: "POST", headers: { "Content-Type": "application/json" }, body: requestPayload },
        );
        // 404 = retired model name, 500/503 = Google overloaded: try the next model.
        if (![404, 500, 503].includes(aiResponse.status)) break;
        await aiResponse.body?.cancel();
      }
      if (!aiResponse) throw new Error("No Gemini model configured.");

      if (aiResponse.status === 429 || aiResponse.status === 503) {
        await releaseSlot();
        // Free-tier quota or burst limit reached: let the app show "try again later".
        return new Response(
          JSON.stringify({ error: "AI_BUSY", message: "The AI is busy right now. Please try again shortly." }),
          { status: 429, headers: { ...corsHeaders, "Content-Type": "application/json" } }
        );
      }

      if (!aiResponse.ok) {
        const errText = await aiResponse.text();
        throw new Error(`AI Provider returned error (${aiResponse.status}): ${errText}`);
      }

      const aiData = await aiResponse.json();
      rawJsonResponse = aiData.candidates?.[0]?.content?.parts?.[0]?.text ?? "";
      if (aiData.usageMetadata) {
        inputTokens = aiData.usageMetadata.promptTokenCount ?? inputTokens;
        outputTokens = aiData.usageMetadata.candidatesTokenCount ?? outputTokens;
      }
    } else {
      // Mock fallback response for offline testing or unconfigured development
      rawJsonResponse = generateSyntheticReportJson(body, validMessageIds);
    }

    // Clean any markdown formatting wrap
    let cleanedJson = rawJsonResponse.trim();
    if (cleanedJson.startsWith("```json")) {
      cleanedJson = cleanedJson.replace(/^```json/, "").replace(/```$/, "").trim();
    } else if (cleanedJson.startsWith("```")) {
      cleanedJson = cleanedJson.replace(/^```/, "").replace(/```$/, "").trim();
    }

    // 7. Parse and Validate JSON
    let parsedPayload: any;
    try {
      parsedPayload = JSON.parse(cleanedJson);
    } catch (e) {
      throw new Error(`Failed to parse AI response as valid JSON: ${e}`);
    }

    // 8. Strict Message ID Verification (Receipt Integrity)
    // Strip any hallucinated IDs that do not exist in the caller's message set!
    if (Array.isArray(parsedPayload.cards)) {
      for (const card of parsedPayload.cards) {
        if (Array.isArray(card.message_ids)) {
          card.message_ids = card.message_ids.filter((id: string) => validMessageIds.has(id));
        } else {
          card.message_ids = [];
        }
      }
    }

    // 9. Cost Accounting
    const costUsd = Number(
      ((inputTokens / 1_000_000) * activeModel.input_cost_per_m +
      (outputTokens / 1_000_000) * activeModel.output_cost_per_m).toFixed(5)
    );

    // Fill in token counts on the reserved usage row.
    if (usageRow?.id) {
      await supabase
        .from("analysis_usage")
        .update({ input_tokens: inputTokens, output_tokens: outputTokens, cost_usd: costUsd })
        .eq("id", usageRow.id);
    }

    const finalResponse: AnalysisResponsePayload = {
      schema_version: 1,
      language: body.output_language,
      relationship_type: body.relationship_type,
      cards: parsedPayload.cards ?? [],
      teaser_insight: parsedPayload.teaser_insight,
      token_usage: {
        input_tokens: inputTokens,
        output_tokens: outputTokens,
        estimated_cost_usd: costUsd,
      },
    };

    return new Response(JSON.stringify(finalResponse), {
      status: 200,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (error: any) {
    await releaseSlot();
    return new Response(
      JSON.stringify({ error: error.message || "An unexpected error occurred during AI analysis." }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});

function generateSyntheticReportJson(req: AnalysisRequestBody, validIds: Set<string>): string {
  const ids = Array.from(validIds);
  const sampleId1 = ids[0] || "msg_1";
  const sampleId2 = ids.length > 1 ? ids[1] : sampleId1;
  const sampleId3 = ids.length > 2 ? ids[2] : sampleId1;

  return JSON.stringify({
    schema_version: 1,
    language: req.output_language,
    relationship_type: req.relationship_type,
    cards: [
      {
        type: "interest_meter",
        title: "Interest & Engagement Meter",
        subtitle: "High mutual conversational energy",
        summary: "Both participants show balanced conversation initiation and fast response patterns across active days.",
        score: 84,
        confidence: "high",
        message_ids: [sampleId1, sampleId2],
      },
      {
        type: "situationship_status",
        title: "Situationship Status",
        subtitle: "Main Character Energy",
        summary: "There is strong banter, regular check-ins, and consistent mutual affection without conversational stalling.",
        score: 88,
        confidence: "high",
        message_ids: [sampleId1],
      },
      {
        type: "simp_score",
        title: "Simp Score",
        subtitle: "Balanced Adoration",
        summary: "Effort is remarkably balanced, though User A initiated slightly more late-night check-ins.",
        score: 38,
        confidence: "medium",
        message_ids: [sampleId2],
      },
      {
        type: "compatibility_score",
        title: "Compatibility Score",
        subtitle: "89% Synergy",
        summary: "Shared sense of humor and aligned texting rhythms indicate high natural chemistry.",
        score: 89,
        confidence: "high",
        message_ids: [sampleId1, sampleId3],
      },
      {
        type: "green_flags",
        title: "Green Flags",
        subtitle: "High emotional responsiveness",
        summary: "Active listening, celebrating personal milestones, and asking thoughtful open questions.",
        confidence: "high",
        message_ids: [sampleId1, sampleId2],
      },
      {
        type: "red_flags",
        title: "Red Flags",
        subtitle: "Occasional delayed replies",
        summary: "Slight reply delays during busy hours, but always followed by genuine apologies and explanations.",
        confidence: "low",
        message_ids: [sampleId3],
      },
      {
        type: "roast_mode",
        title: "Roast Mode",
        subtitle: "The Double-Text Dynasty",
        summary: "Sending three follow-up texts because they took 4 minutes to reply is not a love language, it is conversational cardio.",
        score: 72,
        confidence: "high",
        message_ids: [sampleId2],
      },
      {
        type: "chat_wrapped",
        title: "Chat Wrapped Highlights",
        subtitle: "Top inside jokes & shared phrases",
        summary: "A memorable dynamic filled with late night plans, mutual encouragement, and shared laughter.",
        confidence: "high",
        message_ids: [sampleId1, sampleId3],
      }
    ],
    teaser_insight: {
      type: "interest_meter",
      title: "Interest Meter Sneak Peek",
      subtitle: "84% Conversational Spark",
      summary: "You two have high conversational chemistry with fast replies and shared laughter.",
      score: 84,
      confidence: "high",
      message_ids: [sampleId1],
    }
  });
}
