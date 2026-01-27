import { Data } from "effect";

export class InvokeError extends Data.TaggedError("InvokeError")<{
  message: string;
}> {}

export class KillDeniedError extends Data.TaggedError("KillDeniedError")<{
  pid: number;
  message: string;
}> {}

export class DecodeError extends Data.TaggedError("DecodeError")<{
  message: string;
}> {}
