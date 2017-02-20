{-# LANGUAGE RecursiveDo #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE TemplateHaskell #-}
{-# LANGUAGE RankNTypes #-}
{-# LANGUAGE NoOverloadedStrings #-}

module Gonimo.Client.WebRTC.Message where

import           GHCJS.DOM.RTCIceCandidate
import           GHCJS.DOM.RTCSessionDescription
import           GHCJS.DOM.Types             (Dictionary (..), MonadJSM)
import qualified Gonimo.SocketAPI.Types      as API
import           Language.Javascript.JSaddle (liftJSM, (<#))
import qualified Language.Javascript.JSaddle as JS


toJSIceCandidate :: MonadJSM m => API.IceCandidate -> m RTCIceCandidate
toJSIceCandidate (API.IceCandidate index mid candidate) = liftJSM $ do
  rawDic <- JS.obj
  rawDic <# "sdpMLineIndex" $ index
  rawDic <# "sdpMid" $ mid
  rawDic <# "candidate" $ candidate
  let wrappedDic = case rawDic of JS.Object val -> Dictionary val
  newRTCIceCandidate $ Just wrappedDic

fromJSIceCandidate :: MonadJSM m => RTCIceCandidate -> m API.IceCandidate
fromJSIceCandidate (RTCIceCandidate jsCandidate) = liftJSM $ do
  candidate <- JS.fromJSValUnchecked =<< jsCandidate JS.! "candidate"
  mid <- JS.fromJSValUnchecked =<< jsCandidate JS.! "sdpMid"
  sdpMLineIndex <- JS.fromJSValUnchecked =<< jsCandidate JS.! "sdpMLineIndex"

  -- Don't use API until https://github.com/ghcjs/ghcjs-dom/issues/66 is resolved.
  -- candidate <- getCandidate jsCandidate
  -- mid <- getSdpMid jsCandidate
  -- index <- fromIntegral <$> getSdpMLineIndex jsCandidate
  pure $ API.IceCandidate sdpMLineIndex mid candidate

toJSSessionDescription :: MonadJSM m => API.SessionDescription -> m RTCSessionDescription
toJSSessionDescription (API.SessionDescription sdp type_) = liftJSM $ do
  rawDic <- JS.obj
  rawDic <# "sdp" $ sdp
  rawDic <# "type" $ type_
  let wrappedDic = case rawDic of JS.Object val -> Dictionary val
  newRTCSessionDescription $ Just wrappedDic

fromJSSessionDescription :: MonadJSM m => RTCSessionDescription -> m API.SessionDescription
fromJSSessionDescription jsSession = liftJSM $ do
  sdp <- getSdp jsSession
  type_ <- getType jsSession
  pure $ API.SessionDescription sdp type_
