import { Schema } from "effect";

export const SafetySchema = Schema.Literal("system", "user", "unknown");

export const ProcessInfoSchema = Schema.Struct({
  pid: Schema.Number,
  name: Schema.String,
  description: Schema.String,
  cpu_usage: Schema.Number,
  memory_bytes: Schema.Number,
  safety: SafetySchema,
  exe_path: Schema.String,
});

export const ProcessListSchema = Schema.Array(ProcessInfoSchema);
