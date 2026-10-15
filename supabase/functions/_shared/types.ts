export interface AnalysisRequestBody {
  relationship_type: string;
  output_language: string;
  roast_intensity: string;
  enable_roast: boolean;
  is_teaser_only?: boolean;
  statistics_summary: {
    total_messages: number;
    participant_messages: Record<string, number>;
    avg_response_time_minutes: Record<string, number>;
    double_texts: Record<string, number>;
    conversation_starters: Record<string, number>;
  };
  compact_messages: Array<{
    id: string;
    u: string; // User alias (e.g. "User A", "User B")
    t: string; // Compact timestamp
    c: string; // Message content
  }>;
}

export interface GeneratedReportCard {
  type: string;
  title: string;
  subtitle: string;
  summary: string;
  score?: number;
  confidence: 'low' | 'medium' | 'high';
  message_ids: string[];
  extra_data?: Record<string, unknown>;
}

export interface AnalysisResponsePayload {
  schema_version: 1;
  language: string;
  relationship_type: string;
  cards: GeneratedReportCard[];
  teaser_insight?: GeneratedReportCard;
  token_usage: {
    input_tokens: number;
    output_tokens: number;
    estimated_cost_usd: number;
  };
}
