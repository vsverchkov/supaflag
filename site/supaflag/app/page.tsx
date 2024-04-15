import AuthButton from "../components/AuthButton";
import { createClient } from "@/utils/supabase/server";
import Header from "@/components/Header";
import Alert from "@/components/Alert";

export default async function Index() {
  const supabase = createClient();
  const showRandomForm = await supabase.rpc('is_feature_flag_enabled', { flag_name: 'random.for.anon' });
  const showNewForm = await supabase.rpc('is_feature_flag_enabled', { flag_name: 'show.form.randomly.for.anon' });
  const alertType = showNewForm.data ? 'New' : 'Old';
  const alertMessage = showNewForm.data ? 'Congrats, a new feature shows you randomly!' : 'Sorry, a new feature unavailable for you.';

  return (
    <div className="flex-1 w-full flex flex-col gap-20 items-center">
      <nav className="w-full flex justify-center border-b border-b-foreground/10 h-16">
        <div className="w-full max-w-4xl flex justify-between items-center p-3 text-sm">
          <a className="font-bold text-xl">supaflag</a>
          <AuthButton />
        </div>
      </nav>

      <div className="animate-in flex-1 flex flex-col gap-10 opacity-0 max-w-4xl px-3">
        <Header />
        <main className="flex-1 flex flex-col gap-5">
          <a className="font-bold text-xl mb-5">The next tag was generated based on a random feature flag.</a>
          {showRandomForm.data && <Alert state={alertType} message={alertMessage} />}
          <a className="font-bold text-xl mb-5">Try to reload the page a couple of times.</a>
          <a className="font-bold text-2xl mb-5">Login to see more features!</a>
        </main>
      </div>

      <footer className="w-full border-t border-t-foreground/10 p-8 flex justify-center text-center text-xs">
        <p>
          Powered with{" "}
          <a
            href="https://supabase.com"
            target="_blank"
            className="font-bold hover:underline"
            rel="noreferrer"
          >
            Supabase
          </a>
        </p>
      </footer>
    </div>
  );
}
