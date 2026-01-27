import { invoke } from "@tauri-apps/api/core";
import { Effect, Schema } from "effect";
import type { ProcessInfo } from "../types";
import { DecodeError, InvokeError, KillDeniedError } from "./errors";
import { ProcessListSchema } from "./schemas";

export const getProcesses: Effect.Effect<
  ProcessInfo[],
  InvokeError | DecodeError
> = Effect.tryPromise({
  try: () => invoke<unknown>("get_processes"),
  catch: (error) =>
    new InvokeError({
      message: error instanceof Error ? error.message : String(error),
    }),
}).pipe(
  Effect.flatMap((data) =>
    Effect.try({
      try: () =>
        [...Schema.decodeUnknownSync(ProcessListSchema)(data)] as ProcessInfo[],
      catch: (error) =>
        new DecodeError({
          message: error instanceof Error ? error.message : String(error),
        }),
    }),
  ),
);

export const killProcess = (
  pid: number,
): Effect.Effect<void, InvokeError | KillDeniedError> =>
  Effect.tryPromise({
    try: () => invoke<void>("kill_process", { pid }),
    catch: (error) => {
      const message = error instanceof Error ? error.message : String(error);

      // Check if it's a permission denied error
      if (message.includes("denied") || message.includes("permission")) {
        return new KillDeniedError({ pid, message });
      }

      return new InvokeError({ message });
    },
  });
