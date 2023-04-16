import Link from "next/link";
import { IDKitWidget } from "@worldcoin/idkit";
import type { ISuccessResult } from "@worldcoin/idkit";
import { useCallback } from "react";
import { ConnectButton } from '@rainbow-me/rainbowkit';
import SignInButton from "./SignInButton";


export default function Navbar() {

  const handleProof = useCallback((result: ISuccessResult) => {
		return new Promise<void>((resolve) => {
			setTimeout(() => resolve(), 3000);
			// NOTE: Example of how to decline the verification request and show an error message to the user
		});
	}, []);

	const onSuccess = (result: ISuccessResult) => {
		console.log(result);
	};
    return (
        <>
        <nav className=' flex justify-between h-12 text-green-400 bg-black   font-bold' >
            <span className='mx-20 my-2 flex text-green-400 text-2xl  '><Link href={"/"}>Zen Garden</Link></span>
            <ul className= 'px-2 py-3 flex space-x-10 mx-12 '>
        {/* <div className='flex mx-16 '> */}
          {/* <input className="px-4 h-8  rounded-lg  bg-gray-800 text-gray-400" type="text" placeholder="🔍 Search projects" /> */}
    {/* </div> */}
    
    {/* <div className='hover:text-white delay-50  text-md font-semibold font-mono '>
        <Link href="/">Home</Link></div> */}
    <div className='hover:text-white delay-50  text-md font-semibold font-mono'>
    
        <Link href="/fund">Fund</Link></div>
    <div className='hover:text-white delay-50  text-md font-semibold font-mono'>
    
        <Link href="/meeting">Meet</Link></div>
        <div className='hover:text-white delay-50  text-md font-semibold font-mono'>
    
        <Link href="/marketplace">Marketplace</Link></div>
    <div className='hover:text-white delay-50 text-md font-semibold font-mono '>
    
        <Link href="/notifications">Notifications</Link></div>
          {/* <div className=' mx-2 my-2 '> */}
        <div className='hover:text-white delay-50  text-md font-semibold bg-green-400 text-black rounded-lg px-3 font-mono' >
        <IDKitWidget
					action="my_action"
					signal="my_signal"
					onSuccess={onSuccess}
					handleVerify={handleProof}
					app_id="app_staging_073c6b3b4db6f8d30a1b61634f53c0b5"
					// walletConnectProjectId="get_this_from_walletconnect_portal"
				>
					{({ open }) => <button onClick={open}>Verification</button>}
				</IDKitWidget>
                </div>
    
    <div>
    <ConnectButton/><SignInButton /></div>
        </ul>
    </nav>
    {/* <hr/> */}
    </>
    
    );
    }