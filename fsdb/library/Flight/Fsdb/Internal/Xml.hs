module Flight.Fsdb.Internal.Xml
    ( fsCompetitionNotes
    , fsCustomAttributes
    , fsParticipant
    ) where

import Text.XML.HXT.Core
    ( (>>>)
    , (<+>)
    , XmlTree
    , ArrowXml
    , processTopDown
    , hasName
    , none
    , processAttrl
    , isElem
    , when
    , filterA
    )

fsCompetitionNotes :: ArrowXml a => a XmlTree XmlTree
fsCompetitionNotes =
    processTopDown
        $ none `when` (isElem >>> hasName "FsCompetitionNotes")

fsCustomAttributes :: ArrowXml a => a XmlTree XmlTree
fsCustomAttributes =
    processTopDown
        $ none `when` (isElem >>> hasName "FsCustomAttributes")

-- <FsParticipant
--     id="101"
--     name="Davis Straub"
--     nat_code_3166_a3="USA"
--     female="0"
--     birthday="19XX-XX-XX"
--     glider="Wills Wing T2C 144"
--     glider_main_colors="Blue window"
--     sponsor="The Oz Report"
--     fai_licence="1"
--     CIVLID="XXXX" />
--
-- <FsParticipant ...>
--    <FsCustomAttributes>
--      <FsCustomAttribute name="Grade" value="88"/>
--      <FsCustomAttribute name="Team" value="Team Hangar Door"/>
--    </FsCustomAttributes>
--  </FsParticipant>
fsParticipant :: ArrowXml a => a XmlTree XmlTree
fsParticipant =
    processTopDown
        $ (flip when)
            (isElem >>> hasName "FsParticipant")
            (processAttrl . filterA $ hasName "id" <+> hasName "name")
