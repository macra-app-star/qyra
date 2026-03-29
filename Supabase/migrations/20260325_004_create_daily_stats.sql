CREATE TABLE IF NOT EXISTS public.daily_stats (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    stat_date DATE NOT NULL,
    calories_consumed INT DEFAULT 0,
    protein_g DOUBLE PRECISION DEFAULT 0,
    carbs_g DOUBLE PRECISION DEFAULT 0,
    fat_g DOUBLE PRECISION DEFAULT 0,
    meals_logged INT DEFAULT 0,
    workouts_logged INT DEFAULT 0,
    steps INT DEFAULT 0,
    water_oz DOUBLE PRECISION DEFAULT 0,
    streak_days INT DEFAULT 0,
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, stat_date)
);

ALTER TABLE public.daily_stats ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can read stats of group members" ON public.daily_stats FOR SELECT USING (user_id = auth.uid() OR user_id IN (SELECT gm2.user_id FROM public.group_members gm1 JOIN public.group_members gm2 ON gm1.group_id = gm2.group_id WHERE gm1.user_id = auth.uid()));
CREATE POLICY "Users can upsert own stats" ON public.daily_stats FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own stats" ON public.daily_stats FOR UPDATE USING (auth.uid() = user_id);

CREATE INDEX idx_daily_stats_user_date ON public.daily_stats (user_id, stat_date DESC);
CREATE INDEX idx_daily_stats_date ON public.daily_stats (stat_date);
