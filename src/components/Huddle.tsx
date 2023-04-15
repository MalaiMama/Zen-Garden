import { useHuddle01, useEventListener } from '@huddle01/react';
import { useLobby, useAudio, useVideo, useRoom, usePeers, useMeetingMachine } from '@huddle01/react/hooks';
import { useEffect, useRef } from 'react';
import {Video} from '@huddle01/react/components';

export default function Huddle()  {
  const { initialize, isInitialized } = useHuddle01();
  const { joinLobby } = useLobby();
  const {state} = useMeetingMachine();
 


  const { 
    fetchAudioStream, stopAudioStream, error: micError, 
    produceAudio, stopProducingAudio , stream: micStream
  } = useAudio();

  const { 
    fetchVideoStream, stopVideoStream, error: camError, 
    produceVideo, stopProducingVideo, stream: camStream
  } = useVideo(); 

    const { joinRoom, leaveRoom, isRoomJoined } = useRoom();
 

  const { peerIds, peers } = usePeers();

  useEffect(() => {
    // its preferable to use env vars to store projectId
    initialize('KL1r3E1yHfcrRbXsT4mcE-3mK60Yc3YR');
  }, []);

  const videoRef = useRef<HTMLVideoElement>(null);

  useEventListener('lobby:cam-on', () => {
    if(state.context.camStream && videoRef.current)
    videoRef.current.srcObject = state.context.camStream as MediaStream;
  })

  return (
    <div>{isInitialized ? '' : 'Please initialize'}
    {/* <h4>{JSON.stringify(state.value)}</h4> */}

      {/* <div className="grid grid-cols-4">
        {peerIds.map(peerId => (
            <Video key={peer.peerId} peerId={peer.peerId} debug />
        ))}

        {peerIds.map(peerId => (
            <Audio key={peer.peerId} peerId={peer.peerId} debug />
        ))}
      </div> */}

      <div>
        <button 
          disabled={!joinLobby.isCallable} 
          onClick={() => joinLobby('qge-mlbo-uay')
        }>
          Join Lobby
        </button>
 
      </div>

      
      <button disabled={!fetchAudioStream.isCallable} onClick={fetchAudioStream}>
        FETCH_AUDIO_STREAM
      </button>

      {/* Webcam */} 
      <button disabled={!fetchVideoStream.isCallable} onClick={fetchVideoStream}>
        FETCH_VIDEO_STREAM
      </button>

      <div> 
        <button disabled={!joinRoom.isCallable} onClick={joinRoom}>
          JOIN_ROOM 
        </button>
 
 
        <button disabled={!leaveRoom.isCallable} onClick={leaveRoom}>
          LEAVE_ROOM 
        </button>
      </div>

      <button disabled={!produceVideo.isCallable} onClick={() => produceVideo(camStream)}>
        Produce Cam  
      </button>

      <button disabled={!produceAudio.isCallable} onClick={() => produceAudio(micStream)}>
        Produce Mic  
      </button>

      <button disabled={!stopProducingVideo.isCallable} onClick={stopProducingVideo}>
        Stop Producing Cam  
      </button>

      <button disabled={!stopProducingAudio.isCallable} onClick={stopProducingAudio}>
        Stop Producing Mic  
      </button>
      <video ref={videoRef} autoPlay muted> </video>
<div>
  {Object.values(peers)
  .filter((peer) => peer.cam)
  .map((peer)=>(
    <Video
    key={peer.peerId}
peerId = {peer.peerId}
track = {peer.cam}
debug
/>
    ))
  }
</div>
    </div>
  );
};
