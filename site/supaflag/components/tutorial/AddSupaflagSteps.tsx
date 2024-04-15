import Step from "./Step";

export default function AddSupaflagSteps() {
  return (
    <ol className="flex flex-col gap-6">
      <Step title="Create Supabase project">
        <p>
          Head over to{" "}
          <a
            href="https://app.supabase.com/project/_/settings/api"
            target="_blank"
            className="font-bold hover:underline text-foreground/80"
            rel="noreferrer"
          >
            database.new
          </a>{" "}
          and create a new Supabase project.
        </p>
      </Step>

      <Step title="Create Supaflag tables and functions">
        <p>
          Head over to{" "}
          <a
            href="https://app.supabase.com/project/_/settings/api"
            target="_blank"
            className="font-bold hover:underline text-foreground/80"
            rel="noreferrer"
          >
            supaflag github
          </a>{" "}
          and create a new Supabase project.
        </p>
      </Step>
    </ol>
  )
}
