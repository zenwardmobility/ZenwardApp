import { SectionContainer } from "@/components/public/SectionContainer";
import { typography } from "@/design/typography";
import { cn } from "@/lib/cn";

/**
 * Deliberately not the marketing homepage — that's a later, canonical-screen
 * work item. This route exists so `/` renders something honest rather than
 * the default Next.js template while the public site primitives are built.
 */
export default function Home() {
  return (
    <SectionContainer>
      <h1 className={cn(typography.pageTitleMarketing, "text-text-primary")}>Zenward Mobility</h1>
      <p className={cn(typography.body, "mt-3 max-w-xl text-text-secondary")}>
        Care that gets you there. The public homepage is built in a later phase —
        this page exists to verify the shared public-site primitives.
      </p>
    </SectionContainer>
  );
}
