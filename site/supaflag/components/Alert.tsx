type AlertState = 'New' | 'Old';

type AlertProps = {
  state: AlertState;
  message: string;
}

export default function Alert(props: AlertProps) {
  return props.state === 'New' ? (
    <div className="p-2 bg-indigo-800 items-center text-indigo-100 leading-none lg:rounded-full flex lg:inline-flex mb-5">
      <span className="flex rounded-full bg-indigo-500 uppercase px-2 py-1 text-xs font-bold mr-3">{props.state}</span>
      <span className="font-semibold mr-2 text-left flex-auto">{props.message}</span>
    </div>)
    : (
      <div className="p-2 bg-orange-800 items-center text-orange-100 leading-none lg:rounded-full flex lg:inline-flex mb-5">
        <span className="flex rounded-full bg-orange-500 uppercase px-2 py-1 text-xs font-bold mr-3">{props.state}</span>
        <span className="font-semibold mr-2 text-left flex-auto">{props.message}</span>
      </div>);
}
