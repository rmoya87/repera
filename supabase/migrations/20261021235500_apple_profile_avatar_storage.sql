-- Align Apple-sign-in public profile/avatar API with the installed iOS client.
-- Previously profiles.avatar_url, the storage bucket and UPDATE grants were absent:
-- every native profile sync therefore failed despite successful Apple login.
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS avatar_url text;
GRANT UPDATE(display_name,avatar_url) ON public.profiles TO authenticated;
-- Existing profiles_update_self RLS requires id = auth.uid() for both old/new row.
INSERT INTO storage.buckets(id,name,public,file_size_limit,allowed_mime_types)
VALUES('profile-avatars','profile-avatars',true,2097152,ARRAY['image/jpeg']::text[])
ON CONFLICT(id) DO UPDATE SET file_size_limit=EXCLUDED.file_size_limit,
    allowed_mime_types=EXCLUDED.allowed_mime_types;
-- Exact path: signed-in user's own folder, avatar.jpg only.
CREATE POLICY repera_profile_avatar_insert ON storage.objects
FOR INSERT TO authenticated
WITH CHECK(bucket_id='profile-avatars'
 AND name=(select auth.uid())::text||'/avatar.jpg'
 AND (auth.jwt()->>'client_id') IS NULL);
CREATE POLICY repera_profile_avatar_update ON storage.objects
FOR UPDATE TO authenticated
USING(bucket_id='profile-avatars'
 AND name=(select auth.uid())::text||'/avatar.jpg'
 AND (auth.jwt()->>'client_id') IS NULL)
WITH CHECK(bucket_id='profile-avatars'
 AND name=(select auth.uid())::text||'/avatar.jpg'
 AND (auth.jwt()->>'client_id') IS NULL);
CREATE POLICY repera_profile_avatar_delete ON storage.objects
FOR DELETE TO authenticated USING(bucket_id='profile-avatars'
 AND name=(select auth.uid())::text||'/avatar.jpg'
 AND (auth.jwt()->>'client_id') IS NULL);
CREATE POLICY repera_profile_avatar_select ON storage.objects
FOR SELECT TO authenticated USING(bucket_id='profile-avatars'
 AND name=(select auth.uid())::text||'/avatar.jpg'
 AND (auth.jwt()->>'client_id') IS NULL);
