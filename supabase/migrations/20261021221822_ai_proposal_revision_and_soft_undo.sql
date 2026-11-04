-- Repera MCP v2: optimistic editing of AI proposals, never of athlete-authored workouts.
-- Existing data is untouched; applied plan rows remain immutable over MCP.
ALTER TABLE public.ai_training_plans
 ADD COLUMN IF NOT EXISTS revision integer NOT NULL DEFAULT 1
 CHECK (revision BETWEEN 1 AND 10000);
CREATE INDEX IF NOT EXISTS ai_training_plans_owner_revision_idx
 ON public.ai_training_plans(owner_id,id,revision);
-- Existing status values pending/applied/dismissed implement reversible soft-delete.
-- No extra grants to authenticated iOS clients and no wider publication.
