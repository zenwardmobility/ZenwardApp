import { Input, type InputProps } from "@/components/ui/Input";

export type PublicFormInputProps = Omit<InputProps, "size">;

/** Input sized for public-facing forms (e.g. Request Transportation) — larger touch target than the console default. */
export function PublicFormInput(props: PublicFormInputProps) {
  return <Input size="lg" {...props} />;
}
