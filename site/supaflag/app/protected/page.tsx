import AuthButton from "@/components/AuthButton";
import { createClient } from "@/utils/supabase/server";
import Header from "@/components/Header";
import { redirect } from "next/navigation";
import Alert from "@/components/Alert";

export default async function ProtectedPage() {
  const supabase = createClient();

  const {
    data: { user },
  } = await supabase.auth.getUser();

  if (!user) {
    return redirect("/login");
  }

  const showNewForm = await supabase.rpc('is_feature_flag_enabled', { flag_name: 'show.form.randomly.for.anon' });
  const randomAlertType = showNewForm.data ? 'New' : 'Old';
  const randomAlertMessage = showNewForm.data ? 'Congrats, a new feature shows you randomly!' : 'Sorry, a new feature unavailable for you.';

  const showFormForUser = await supabase.rpc('is_feature_flag_enabled', { flag_name: 'show.form.stickness.by.user.id' });
  const userAlertType = showFormForUser.data ? 'New' : 'Old';
  const userAlertMessage = showFormForUser.data
    ? 'Your user got into the feature by hashing'
    : 'Sorry, your user did not get into feature by hashing';

  const showFormForSession = await supabase.rpc('is_feature_flag_enabled', { flag_name: 'show.form.stickness.by.session.id' });
  const sesionAlertType = showFormForSession.data ? 'New' : 'Old';
  const sessionAlertMessage = showFormForSession.data
    ? 'Your session got into the feature by hashing'
    : 'Sorry, your session did not get into feature by hashing';

  const showFormForSelectedUser = await supabase.rpc('is_feature_flag_enabled', { flag_name: 'show.form.selected.by.user.id' });
  const selectedUserAlertType = showFormForSelectedUser.data ? 'New' : 'Old';
  const selectedAlertMessage = showFormForSelectedUser.data
    ? 'Congrats, you are in a private club'
    : 'Sorry, you are not in a private club yet';

  return (
    <div className="flex-1 w-full flex flex-col gap-20 items-center">
      <div className="w-full">
        <nav className="w-full flex justify-center border-b border-b-foreground/10 h-16">
          <div className="w-full max-w-4xl flex justify-between items-center p-3 text-sm">
            <a className="font-bold text-xl">supaflag</a>
            <AuthButton />
          </div>
        </nav>
      </div>

      <div className="animate-in flex-1 flex flex-col gap-10 opacity-0 max-w-4xl px-3">
        <Header />
        <main className="flex-1 flex flex-col gap-5">
          <a className="font-bold text-xl mb-5">The next tag was generated based on a random feature flag.</a>
          <Alert state={randomAlertType} message={randomAlertMessage} />
          <a className="font-bold text-xl mb-20">Try to reload the page a couple of times.</a>
          <a className="font-bold text-xl mb-5">The next tag was generated based on a hashed (by user id) feature flag.</a>
          <Alert state={userAlertType} message={userAlertMessage} />
          <a className="font-bold text-xl mb-20">Sorry, reloading won't help.</a>
          <a className="font-bold text-xl mb-5">The next tag was generated based on a hashed (by session id) feature flag.</a>
          <Alert state={sesionAlertType} message={sessionAlertMessage} />
          <a className="font-bold text-xl mb-20">Try to relogin a couple of times.</a>
          <a className="font-bold text-xl mb-5">The next tag was generated based on selected users feature flag.</a>
          <Alert state={selectedUserAlertType} message={selectedAlertMessage} />
          <a className="font-bold text-xl mb-5">You can text me and I will add you to a club.</a>
        </main>
      </div>

      <footer className="w-full border-t border-t-foreground/10 p-8 flex justify-center text-center text-xs">
        <p>
          Powered with{" "}
          <a
            href="https://supabase.com/?utm_source=create-next-app&utm_medium=template&utm_term=nextjs"
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
