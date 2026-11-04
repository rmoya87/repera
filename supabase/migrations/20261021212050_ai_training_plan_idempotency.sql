-- Avoid duplicate AI plans when an MCP tool call is retried by a model
-- or loses its HTTP acknowledgement. Batch IDs are deterministic when
-- caller supplies an idempotency UUID. Never overwrite a pre-existing plan.
CREATE UNIQUE INDEX ai_training_plans_owner_batch_date_uq
  ON public.ai_training_plans(owner_id,batch_id,scheduled_date);
