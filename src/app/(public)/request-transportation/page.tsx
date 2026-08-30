import { SectionContainer } from "@/components/public/SectionContainer";
import { typography } from "@/design/typography";
import { cn } from "@/lib/cn";

/**
 * Structural placeholder — the canonical Request Transportation screen
 * (the public booking flow) is built in a later phase.
 */
export default function RequestTransportationPage() {
  return (
    <SectionContainer>
      <h1 className={cn(typography.pageTitleMarketing, "text-text-primary")}>Request Transportation</h1>
      <p className={cn(typography.body, "mt-3 max-w-xl text-text-secondary")}>
        This route is a structural placeholder — the canonical request flow is built in a later phase.
      </p>
    </SectionContainer>
  );
}
