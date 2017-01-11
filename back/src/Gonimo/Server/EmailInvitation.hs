{-# LANGUAGE QuasiQuotes #-}
{-# LANGUAGE CPP #-}
module Gonimo.Server.EmailInvitation (
  makeInvitationEmail) where

import           Data.Text                ()
import           Data.Text                as T
import           Data.Text.Encoding       as T
#ifndef DEVELOPMENT
import           NeatInterpolation
#else
import           Data.Monoid
#endif
import           Network.Mail.Mime        (Address (..), Mail, simpleMail')
import qualified Data.Text.Lazy           as TL
import qualified Data.ByteString.Lazy as BL
import           Network.HTTP.Types (urlEncode)

import           Gonimo.Db.Entities (Invitation(..))
import           Gonimo.Types
import qualified Data.Aeson as Aeson


#ifdef DEVELOPMENT
invitationText :: Invitation -> FamilyName -> Text
invitationText _inv (FamilyName _ _n) = "New invitation for family "
    <> _n
    <> ":\nhttp://localhost:8081/index.html?acceptInvitation="
    <> secret
    <> "\n"
  where
    secret = T.decodeUtf8 . urlEncode True . encodeStrict $ invitationSecret _inv
    encodeStrict = BL.toStrict . Aeson.encode
#else
invitationText :: Invitation -> FamilyName -> Text
invitationText _inv (FamilyName _ _n) =
  [text|
    Dear User of gonimo.com!

    You got invited to join gonimo family "$_n"!
    Just click on the link below and you are all set for the best baby monitoring on the planet!

    https://dev.gonimo.com/index.html?acceptInvitation=$secret

    Sincerely yours,

    Gonimo
  |]
  where
    secret = T.decodeUtf8 . urlEncode True . encodeStrict $ invitationSecret _inv
    encodeStrict = BL.toStrict . Aeson.encode
#endif

makeInvitationEmail :: Invitation -> EmailAddress -> FamilyName -> Mail
makeInvitationEmail inv addr name = simpleMail' receiver sender "You got invited to a family on gonimo.com" (TL.fromStrict textContent)
  where
    textContent = invitationText inv name
    receiver = Address Nothing addr
    sender = if T.isSuffixOf "gonimo.com" addr
      then Address Nothing "noreply@baby.gonimo.com" -- So we can send emails to ourself. (noreply@gonimo.com gets blocked by easyname)
      else Address Nothing "noreply@gonimo.com"