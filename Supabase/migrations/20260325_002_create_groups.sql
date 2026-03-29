CREATE TABLE IF NOT EXISTS public.groups (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    name TEXT NOT NULL,
    invite_code TEXT UNIQUE NOT NULL,
    created_by UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    is_private BOOLEAN DEFAULT false,
    max_members INT DEFAULT 50,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.group_members (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    group_id UUID NOT NULL REFERENCES public.groups(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    role TEXT DEFAULT 'member',
    joined_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(group_id, user_id)
);

ALTER TABLE public.groups ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.group_members ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Members can read their groups" ON public.groups FOR SELECT USING (id IN (SELECT group_id FROM public.group_members WHERE user_id = auth.uid()) OR invite_code IS NOT NULL);
CREATE POLICY "Authenticated users can create groups" ON public.groups FOR INSERT WITH CHECK (auth.uid() = created_by);
CREATE POLICY "Group owners can update" ON public.groups FOR UPDATE USING (created_by = auth.uid());
CREATE POLICY "Group owners can delete" ON public.groups FOR DELETE USING (created_by = auth.uid());
CREATE POLICY "Members can see group members" ON public.group_members FOR SELECT USING (group_id IN (SELECT group_id FROM public.group_members WHERE user_id = auth.uid()));
CREATE POLICY "Users can join groups" ON public.group_members FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can leave groups" ON public.group_members FOR DELETE USING (auth.uid() = user_id);

CREATE INDEX idx_groups_invite_code ON public.groups (invite_code);
CREATE INDEX idx_group_members_user ON public.group_members (user_id);
CREATE INDEX idx_group_members_group ON public.group_members (group_id);
