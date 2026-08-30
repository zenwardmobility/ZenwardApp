import { SectionContainer } from "@/components/public/SectionContainer";
import { typography } from "@/design/typography";
import { cn } from "@/lib/cn";

/**
 * Structural placeholder — the canonical healthcare-provider/facility
 * landing page is built in a later phase.
 */
export default function HealthcareProvidersPage() {
  return (
    <SectionContainer>
      <h1 className={cn(typography.pageTitleMarketing, "text-text-primary")}>For Healthcare Providers</h1>
      <p className={cn(typography.body, "mt-3 max-w-xl text-text-secondary")}>
        This route is a structural placeholder — the canonical facility/referral-partner page is built in a
        later phase.
      </p>
    </SectionContainer>
  );
}
