import Link from "next/link";

export default function Header() {
  return (
    <div className="flex flex-col gap-10 items-center">
      <h1 className="sr-only">Supaflag</h1>
      <p className="text-3xl lg:text-4xl !leading-tight mx-auto max-w-xl text-center">
        The simplest way to manage app features with{" "}
        <a
          href="https://supabase.com"
          target="_blank"
          className="font-bold hover:underline"
          rel="noreferrer"
        >
          supabase
        </a>
      </p>
      <Link
        href="https://github.com/vsverchkov/supaflag?tab=readme-ov-file#getting-started-with-supaflag"
        className="text-zinc-900 py-3 px-4 flex rounded-md no-underline bg-zinc-50 hover:bg-gray-200"
      >
        Get Started
      </Link>
      <div className="w-full p-[1px] bg-gradient-to-r from-transparent via-foreground/10 to-transparent my-8" />
    </div>
  );
}
