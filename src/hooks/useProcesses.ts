import { Effect, Fiber, Schedule } from "effect";
import { useEffect, useState } from "react";
import { runtime } from "../lib/runtime";
import { getProcesses } from "../services/commands";
import type { ProcessInfo } from "../types";

export function useProcesses() {
  const [processes, setProcesses] = useState<ProcessInfo[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    // Create a polling effect that runs every 2 seconds
    const pollingEffect = getProcesses.pipe(
      Effect.tap((procs) =>
        Effect.sync(() => {
          setProcesses(procs);
          setLoading(false);
          setError(null);
        }),
      ),
      Effect.catchAll((err) =>
        Effect.sync(() => {
          setError(err.message);
          setLoading(false);
        }),
      ),
      Effect.repeat(Schedule.spaced("2 seconds")),
    );

    // Fork the polling effect as a fiber
    const fiber = runtime.runFork(pollingEffect);

    // Cleanup: interrupt the fiber on unmount
    return () => {
      runtime.runFork(Fiber.interrupt(fiber));
    };
  }, []);

  return { processes, loading, error };
}
