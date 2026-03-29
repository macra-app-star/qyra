-- Analytics events table for macra
CREATE TABLE IF NOT EXISTS public.analytics_events (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    event_name TEXT NOT NULL,
    properties JSONB DEFAULT '{}',
    event_timestamp TIMESTAMPTZ NOT NULL,
    session_id TEXT NOT NULL,
    device_id TEXT,
    ingested_at TIMESTAMPTZ DEFAULT NOW(),

    CONSTRAINT analytics_events_name_check CHECK (char_length(event_name) <= 100)
);

-- Index for querying by user + time range (retention analysis)
CREATE INDEX idx_analytics_user_timestamp ON public.analytics_events (user_id, event_timestamp DESC);

-- Index for querying by event name (funnel analysis)
CREATE INDEX idx_analytics_event_name ON public.analytics_events (event_name, event_timestamp DESC);

-- Index for session-based queries
CREATE INDEX idx_analytics_session ON public.analytics_events (session_id);

-- RLS: Users can only insert their own events, admins can read all
ALTER TABLE public.analytics_events ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can insert own events"
    ON public.analytics_events
    FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can read own events"
    ON public.analytics_events
    FOR SELECT
    USING (auth.uid() = user_id);

COMMENT ON TABLE public.analytics_events IS 'Client-side analytics events from macra iOS app. Partition by event_timestamp when row count exceeds 10M.';
