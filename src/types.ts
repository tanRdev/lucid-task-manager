import type { Schema } from "effect";
import type { ProcessInfoSchema, SafetySchema } from "./services/schemas";

export type ProcessInfo = Schema.Schema.Type<typeof ProcessInfoSchema>;
export type Safety = Schema.Schema.Type<typeof SafetySchema>;
