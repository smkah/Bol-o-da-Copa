import { createClient, SupabaseClient } from '@supabase/supabase-js';

let supabaseInstance: SupabaseClient | null = null;

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL;
const supabaseAnonKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY;

export const isSupabaseConfigured = !!supabaseUrl && !!supabaseAnonKey;

export const getSupabase = () => {
  if (supabaseInstance) return supabaseInstance;

  if (!isSupabaseConfigured) {
    if (typeof window !== 'undefined') {
      console.error('CRITICAL: Supabase credentials missing!');
      console.info('To fix this "Failed to fetch" error, you must add NEXT_PUBLIC_SUPABASE_URL and NEXT_PUBLIC_SUPABASE_ANON_KEY to your environment variables or AI Studio Secrets.');
    }
    // Return a dummy client to prevent crashes, but it will fail on calls
    return createClient('https://placeholder-project.supabase.co', 'placeholder-key');
  }

  supabaseInstance = createClient(supabaseUrl!, supabaseAnonKey!);
  return supabaseInstance;
};

export const supabase = getSupabase();
