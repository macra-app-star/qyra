CREATE TABLE IF NOT EXISTS public.versus_challenges (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    name TEXT NOT NULL,
    metric TEXT NOT NULL,
    created_by UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    group_id UUID REFERENCES public.groups(id) ON DELETE SET NULL,
    start_date TIMESTAMPTZ NOT NULL,
    end_date TIMESTAMPTZ NOT NULL,
    stakes TEXT,
    status TEXT DEFAULT 'pending',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.versus_participants (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    challenge_id UUID NOT NULL REFERENCES public.versus_challenges(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    score DOUBLE PRECISION DEFAULT 0,
    accepted BOOLEAN DEFAULT false,
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(challenge_id, user_id)
);

ALTER TABLE public.versus_challenges ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.versus_participants ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Participants can see challenges" ON public.versus_challenges FOR SELECT USING (id IN (SELECT challenge_id FROM public.versus_participants WHERE user_id = auth.uid()) OR created_by = auth.uid());
CREATE POLICY "Authenticated users can create challenges" ON public.versus_challenges FOR INSERT WITH CHECK (auth.uid() = created_by);
CREATE POLICY "Creator can update challenge" ON public.versus_challenges FOR UPDATE USING (created_by = auth.uid());
CREATE POLICY "Participants can see other participants" ON public.versus_participants FOR SELECT USING (challenge_id IN (SELECT challenge_id FROM public.versus_participants WHERE user_id = auth.uid()));
CREATE POLICY "Users can join challenges" ON public.versus_participants FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own score" ON public.versus_participants FOR UPDATE USING (auth.uid() = user_id);

CREATE INDEX idx_versus_participants_user ON public.versus_participants (user_id);
CREATE INDEX idx_versus_challenges_group ON public.versus_challenges (group_id);
CREATE INDEX idx_versus_challenges_status ON public.versus_challenges (status);
