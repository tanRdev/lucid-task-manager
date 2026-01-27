import { Layer, ManagedRuntime } from "effect";

export const runtime = ManagedRuntime.make(Layer.empty);
