import { createClient } from '@supabase/supabase-js';

const supabaseUrl =
  import.meta.env.VITE_SUPABASE_URL || 'https://bgxmcgsfkjhpocptrezi.supabase.co';
const supabasePublishableKey =
  import.meta.env.VITE_SUPABASE_PUBLISHABLE_KEY || 'sb_publishable_18hn9O3SKu_Sr1H7RRGVKw_5lnb8UJL';

export const supabase = createClient(supabaseUrl, supabasePublishableKey);
