-- 1. Tabela de Perfis (Profiles)
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID REFERENCES auth.users ON DELETE CASCADE PRIMARY KEY,
    email TEXT UNIQUE NOT NULL,
    full_name TEXT,
    points INTEGER DEFAULT 0,
    ranking_position INTEGER,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. Tabela de Partidas (Matches)
CREATE TABLE IF NOT EXISTS public.matches (
    id TEXT PRIMARY KEY,
    team1 TEXT NOT NULL,
    team2 TEXT NOT NULL,
    score1 INTEGER,
    score2 INTEGER,
    date TEXT NOT NULL,
    time TEXT NOT NULL,
    "group" TEXT,
    round TEXT NOT NULL,
    ground TEXT,
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. Tabela de Bolões (Groups)
CREATE TABLE IF NOT EXISTS public.groups (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    name TEXT NOT NULL,
    code TEXT UNIQUE NOT NULL,
    created_by UUID NOT NULL CONSTRAINT groups_created_by_fkey REFERENCES public.profiles(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Adicionar colunas de configuração caso não existam (Migração)
DO $$ 
BEGIN 
    IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME='groups' AND COLUMN_NAME='points_winner') THEN
        ALTER TABLE public.groups ADD COLUMN points_winner INTEGER DEFAULT 3;
        ALTER TABLE public.groups ADD COLUMN points_exact INTEGER DEFAULT 5;
        ALTER TABLE public.groups ADD COLUMN points_first_half INTEGER DEFAULT 2;
        ALTER TABLE public.groups ADD COLUMN custom_rules JSONB DEFAULT '{}'::jsonb;
    END IF;
END $$;

-- 4. Tabela de Membros de Grupos (Group Members)
CREATE TABLE IF NOT EXISTS public.group_members (
    group_id UUID REFERENCES public.groups(id) ON DELETE CASCADE,
    profile_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    joined_at TIMESTAMPTZ DEFAULT NOW(),
    PRIMARY KEY (group_id, profile_id)
);

-- 5. Tabela de Palpites (Guesses)
CREATE TABLE IF NOT EXISTS public.guesses (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    profile_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    match_id TEXT REFERENCES public.matches(id),
    score1 INTEGER NOT NULL,
    score2 INTEGER NOT NULL,
    points_earned INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(profile_id, match_id)
);

-- CONFIGURAÇÃO DE SEGURANÇA (RLS)
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.matches ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.groups ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.group_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.guesses ENABLE ROW LEVEL SECURITY;

-- Funções Auxiliares
CREATE OR REPLACE FUNCTION is_admin()
RETURNS BOOLEAN AS $$
BEGIN
  RETURN (SELECT email FROM auth.users WHERE id = auth.uid()) = 'samukahweb@gmail.com';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Limpar políticas existentes para evitar erros de duplicata na execução
DO $$ 
BEGIN
    DROP POLICY IF EXISTS "Profiles são visíveis por todos" ON public.profiles;
    DROP POLICY IF EXISTS "Usuários podem editar seu próprio perfil" ON public.profiles;
    DROP POLICY IF EXISTS "Admin pode gerenciar perfis" ON public.profiles;
    DROP POLICY IF EXISTS "Partidas são visíveis por todos" ON public.matches;
    DROP POLICY IF EXISTS "Admin pode gerenciar partidas" ON public.matches;
    DROP POLICY IF EXISTS "Grupos são visíveis por todos autenticados" ON public.groups;
    DROP POLICY IF EXISTS "Usuários podem criar grupos" ON public.groups;
    DROP POLICY IF EXISTS "Criador pode gerenciar seu grupo" ON public.groups;
    DROP POLICY IF EXISTS "Membros são visíveis por todos autenticados" ON public.group_members;
    DROP POLICY IF EXISTS "Usuários podem entrar em grupos" ON public.group_members;
    DROP POLICY IF EXISTS "Usuários podem sair de grupos" ON public.group_members;
    DROP POLICY IF EXISTS "Palpites são privados ao dono" ON public.guesses;
    DROP POLICY IF EXISTS "Usuários podem criar/editar seus palpites" ON public.guesses;
END $$;

-- Recriar POLÍTICAS 
CREATE POLICY "Profiles são visíveis por todos" ON public.profiles FOR SELECT USING (true);
CREATE POLICY "Usuários podem criar seu próprio perfil" ON public.profiles FOR INSERT WITH CHECK (auth.uid() = id);
CREATE POLICY "Usuários podem editar seu próprio perfil" ON public.profiles FOR UPDATE USING (auth.uid() = id);
CREATE POLICY "Admin pode gerenciar perfis" ON public.profiles FOR ALL USING (is_admin());

CREATE POLICY "Partidas são visíveis por todos" ON public.matches FOR SELECT USING (true);
CREATE POLICY "Admin pode gerenciar partidas" ON public.matches FOR ALL USING (is_admin());

CREATE POLICY "Grupos são visíveis por todos autenticados" ON public.groups FOR SELECT USING (auth.uid() IS NOT NULL);
CREATE POLICY "Usuários podem criar grupos" ON public.groups FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);
CREATE POLICY "Criador pode gerenciar seu grupo" ON public.groups FOR ALL USING (auth.uid() = created_by OR is_admin());

CREATE POLICY "Membros são visíveis por todos autenticados" ON public.group_members FOR SELECT USING (auth.uid() IS NOT NULL);
CREATE POLICY "Usuários podem entrar em grupos" ON public.group_members FOR INSERT WITH CHECK (auth.uid() = profile_id OR is_admin());
CREATE POLICY "Usuários podem sair de grupos" ON public.group_members FOR DELETE USING (auth.uid() = profile_id OR is_admin());
CREATE POLICY "Admin pode gerenciar membros" ON public.group_members FOR ALL USING (is_admin());

CREATE POLICY "Palpites são privados ao dono" ON public.guesses FOR SELECT USING (auth.uid() = profile_id OR is_admin());
CREATE POLICY "Usuários podem criar/editar seus palpites" ON public.guesses FOR ALL USING (auth.uid() = profile_id OR is_admin());
CREATE POLICY "Admin pode gerenciar palpites" ON public.guesses FOR ALL USING (is_admin());

-- TRIGGER PARA CRIAR PERFIL NO SIGNUP
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, email, full_name, points)
  VALUES (new.id, new.email, new.raw_user_meta_data->>'full_name', 0)
  ON CONFLICT (id) DO NOTHING;
  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE PROCEDURE public.handle_new_user();
