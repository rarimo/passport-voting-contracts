// SPDX-License-Identifier: GPL-3.0
/*
    Copyright 2021 0KIMS association.

    This file is generated with [snarkJS](https://github.com/iden3/snarkjs).

    snarkJS is a free software: you can redistribute it and/or modify it
    under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    snarkJS is distributed in the hope that it will be useful, but WITHOUT
    ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
    or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public
    License for more details.

    You should have received a copy of the GNU General Public License
    along with snarkJS. If not, see <https://www.gnu.org/licenses/>.
*/

pragma solidity >=0.7.0 <0.9.0;

contract VotingVerifier {
    // Scalar field size
    uint256 constant r =
        21888242871839275222246405745257275088548364400416034343698204186575808495617;
    // Base field size
    uint256 constant q =
        21888242871839275222246405745257275088696311157297823662689037894645226208583;

    // Verification Key data
    uint256 constant alphax =
        20491192805390485299153009773594534940189261866228447918068658471970481763042;
    uint256 constant alphay =
        9383485363053290200918347156157836566562967994039712273449902621266178545958;
    uint256 constant betax1 =
        4252822878758300859123897981450591353533073413197771768651442665752259397132;
    uint256 constant betax2 =
        6375614351688725206403948262868962793625744043794305715222011528459656738731;
    uint256 constant betay1 =
        21847035105528745403288232691147584728191162732299865338377159692350059136679;
    uint256 constant betay2 =
        10505242626370262277552901082094356697409835680220590971873171140371331206856;
    uint256 constant gammax1 =
        11559732032986387107991004021392285783925812861821192530917403151452391805634;
    uint256 constant gammax2 =
        10857046999023057135944570762232829481370756359578518086990519993285655852781;
    uint256 constant gammay1 =
        4082367875863433681332203403145435568316851327593401208105741076214120093531;
    uint256 constant gammay2 =
        8495653923123431417604973247489272438418190587263600148770280649306958101930;
    uint256 constant deltax1 =
        9891043720280220628692915542727234723176342602842047084314631698167024144780;
    uint256 constant deltax2 =
        250995107149602303902723825982283137581400378217631271450447238979029817078;
    uint256 constant deltay1 =
        2501606002450797961398382109784584155920579048580401544376144432520473660114;
    uint256 constant deltay2 =
        21598751604233084552631128264788494971225705751943392705633744284742282927110;

    uint256 constant IC0x =
        17504052607720179796029381668301757338081966454009243468177923271980574814243;
    uint256 constant IC0y =
        6499664010915768263025671400458090450472438360011757405904555283230039207798;

    uint256 constant IC1x =
        1357575287307716204332608853701215549412089465128628814266936007148057376779;
    uint256 constant IC1y =
        3713766987380338685445896004327981318598581633792705722551102736624658007564;

    uint256 constant IC2x =
        15747026641952926109104985431357649859491920901639733373025871367980094366768;
    uint256 constant IC2y =
        2021878086299767722307546756257572854357051561560741909092770885515051640911;

    uint256 constant IC3x =
        11075366624062668195785703962771246295234482566189756832667494420072616502700;
    uint256 constant IC3y =
        5420346121279755362883215215727059531159527965307489085576017377764991212018;

    uint256 constant IC4x =
        20368848384139638082817177286079325397016405641114382149956158523375737541890;
    uint256 constant IC4y =
        1572073918100899470387834817789604618967295393862588865982200378334199073381;

    uint256 constant IC5x =
        4884540123112420465154970511637257053826210976956994828071389921227262341444;
    uint256 constant IC5y =
        4401673700279739045268386131201872330056492033989625057664756337448169387800;

    uint256 constant IC6x =
        16470227635722111182924309537921818774284668434861990652213066309576613376597;
    uint256 constant IC6y =
        10574627744256450338226549222335655558440631228160972004945424930608743239054;

    uint256 constant IC7x =
        19418983452178510217439686273441678721042270520673788318708474056801008635540;
    uint256 constant IC7y =
        5954053904211612943354309791765614531909014497153829150028696655549715331300;

    uint256 constant IC8x =
        19969835639743236239835298046556892476301204281035394416541396844103009106355;
    uint256 constant IC8y =
        3464048236750799763830774306163631257686652073410502150568025357895609835087;

    uint256 constant IC9x =
        16889360220018193750070483451098248942399422264467650117676317744570511901000;
    uint256 constant IC9y =
        19163095658023449989360365284122431970258115105696535743555631104342701965620;

    uint256 constant IC10x =
        2000598533781950880616032153963991095870880760490607748033546349673742925320;
    uint256 constant IC10y =
        20321987334373319808455108419208620186197650703759507527460278164750299812594;

    uint256 constant IC11x =
        16622794560388092172406300251846507876295531384651110810529046702689230241671;
    uint256 constant IC11y =
        1168900337587520742769049240681077756007030111701401232363112514557957065414;

    uint256 constant IC12x =
        20003036160055551712788940815733718770555763081531584216892303399668712478110;
    uint256 constant IC12y =
        2174533660069731906049631044938252962750066370758164479572834908198694151084;

    uint256 constant IC13x =
        11772665925032384718253555051633531838829671820497340300185967148297677039379;
    uint256 constant IC13y =
        6192398587210616471820050022235488819084933415616256899737060483561024906606;

    uint256 constant IC14x =
        15657742438066830139511651433271232123522643695336399042468768927770968777317;
    uint256 constant IC14y =
        11257143988485946647061649132368606627111178376998178535183131249025707609666;

    uint256 constant IC15x =
        3557755399773759765444169665412070984458161190003566583170847762650863824131;
    uint256 constant IC15y =
        9162528146429684487918103018996309472779246016088040951661601742822058701071;

    uint256 constant IC16x =
        4911244036897574121015612240189284264968921600337359791288016634397162953143;
    uint256 constant IC16y =
        20098567466767577245421277892831169895963838853958362747460137045849263159162;

    uint256 constant IC17x =
        1135107237735552968313239550154221137067895575647377673548240870567407026247;
    uint256 constant IC17y =
        12619799164591187815955097034071604825882733672329684869943904028286332886950;

    uint256 constant IC18x =
        18719326153459121647252500180221787149624427888924649239267373118826345738344;
    uint256 constant IC18y =
        6174837817190288410366533190883421410927048311934272958561612197947539226864;

    uint256 constant IC19x =
        14068815473069882733560986185720538386198373373910560000001545446350275283111;
    uint256 constant IC19y =
        2263864788552528575269174822385765238579264081503908544056370563901781433374;

    uint256 constant IC20x =
        13681287665806075575234946534131390573378321747271934504111831172099326553217;
    uint256 constant IC20y =
        3862217688704157961463555733433779593310753701296453080215768440686462093765;

    uint256 constant IC21x =
        10124975593322782194920136435156615190114785409379480926175765230056237270040;
    uint256 constant IC21y =
        11883756580458974292436402091967718449327148002023702956543175856868564195868;

    uint256 constant IC22x =
        7583087196404385822216091174292782109474245466645430940072499274718408481450;
    uint256 constant IC22y =
        7908253210251899913336547162702007719697657344405972857500065180060089017299;

    uint256 constant IC23x =
        10744666798601271589203622228576516180789086810962571663046391661836304523997;
    uint256 constant IC23y =
        20584110500062975100789500023059589458238450321066873580677100473621660271307;

    uint256 constant IC24x =
        13504462623041613508499662626532960766655354187840105839904395325552754762194;
    uint256 constant IC24y =
        5095871316273261363289391506065716930115839445347141940606131201185100201565;

    // Memory data
    uint16 constant pVk = 0;
    uint16 constant pPairing = 128;

    uint16 constant pLastMem = 896;

    function verifyProof(
        uint[2] calldata _pA,
        uint[2][2] calldata _pB,
        uint[2] calldata _pC,
        uint[24] calldata _pubSignals
    ) public view returns (bool) {
        assembly {
            function checkField(v) {
                if iszero(lt(v, q)) {
                    mstore(0, 0)
                    return(0, 0x20)
                }
            }

            // G1 function to multiply a G1 value(x,y) to value in an address
            function g1_mulAccC(pR, x, y, s) {
                let success
                let mIn := mload(0x40)
                mstore(mIn, x)
                mstore(add(mIn, 32), y)
                mstore(add(mIn, 64), s)

                success := staticcall(sub(gas(), 2000), 7, mIn, 96, mIn, 64)

                if iszero(success) {
                    mstore(0, 0)
                    return(0, 0x20)
                }

                mstore(add(mIn, 64), mload(pR))
                mstore(add(mIn, 96), mload(add(pR, 32)))

                success := staticcall(sub(gas(), 2000), 6, mIn, 128, pR, 64)

                if iszero(success) {
                    mstore(0, 0)
                    return(0, 0x20)
                }
            }

            function checkPairing(pA, pB, pC, pubSignals, pMem) -> isOk {
                let _pPairing := add(pMem, pPairing)
                let _pVk := add(pMem, pVk)

                mstore(_pVk, IC0x)
                mstore(add(_pVk, 32), IC0y)

                // Compute the linear combination vk_x

                g1_mulAccC(_pVk, IC1x, IC1y, calldataload(add(pubSignals, 0)))

                g1_mulAccC(_pVk, IC2x, IC2y, calldataload(add(pubSignals, 32)))

                g1_mulAccC(_pVk, IC3x, IC3y, calldataload(add(pubSignals, 64)))

                g1_mulAccC(_pVk, IC4x, IC4y, calldataload(add(pubSignals, 96)))

                g1_mulAccC(_pVk, IC5x, IC5y, calldataload(add(pubSignals, 128)))

                g1_mulAccC(_pVk, IC6x, IC6y, calldataload(add(pubSignals, 160)))

                g1_mulAccC(_pVk, IC7x, IC7y, calldataload(add(pubSignals, 192)))

                g1_mulAccC(_pVk, IC8x, IC8y, calldataload(add(pubSignals, 224)))

                g1_mulAccC(_pVk, IC9x, IC9y, calldataload(add(pubSignals, 256)))

                g1_mulAccC(_pVk, IC10x, IC10y, calldataload(add(pubSignals, 288)))

                g1_mulAccC(_pVk, IC11x, IC11y, calldataload(add(pubSignals, 320)))

                g1_mulAccC(_pVk, IC12x, IC12y, calldataload(add(pubSignals, 352)))

                g1_mulAccC(_pVk, IC13x, IC13y, calldataload(add(pubSignals, 384)))

                g1_mulAccC(_pVk, IC14x, IC14y, calldataload(add(pubSignals, 416)))

                g1_mulAccC(_pVk, IC15x, IC15y, calldataload(add(pubSignals, 448)))

                g1_mulAccC(_pVk, IC16x, IC16y, calldataload(add(pubSignals, 480)))

                g1_mulAccC(_pVk, IC17x, IC17y, calldataload(add(pubSignals, 512)))

                g1_mulAccC(_pVk, IC18x, IC18y, calldataload(add(pubSignals, 544)))

                g1_mulAccC(_pVk, IC19x, IC19y, calldataload(add(pubSignals, 576)))

                g1_mulAccC(_pVk, IC20x, IC20y, calldataload(add(pubSignals, 608)))

                g1_mulAccC(_pVk, IC21x, IC21y, calldataload(add(pubSignals, 640)))

                g1_mulAccC(_pVk, IC22x, IC22y, calldataload(add(pubSignals, 672)))

                g1_mulAccC(_pVk, IC23x, IC23y, calldataload(add(pubSignals, 704)))

                g1_mulAccC(_pVk, IC24x, IC24y, calldataload(add(pubSignals, 736)))

                // -A
                mstore(_pPairing, calldataload(pA))
                mstore(add(_pPairing, 32), mod(sub(q, calldataload(add(pA, 32))), q))

                // B
                mstore(add(_pPairing, 64), calldataload(pB))
                mstore(add(_pPairing, 96), calldataload(add(pB, 32)))
                mstore(add(_pPairing, 128), calldataload(add(pB, 64)))
                mstore(add(_pPairing, 160), calldataload(add(pB, 96)))

                // alpha1
                mstore(add(_pPairing, 192), alphax)
                mstore(add(_pPairing, 224), alphay)

                // beta2
                mstore(add(_pPairing, 256), betax1)
                mstore(add(_pPairing, 288), betax2)
                mstore(add(_pPairing, 320), betay1)
                mstore(add(_pPairing, 352), betay2)

                // vk_x
                mstore(add(_pPairing, 384), mload(add(pMem, pVk)))
                mstore(add(_pPairing, 416), mload(add(pMem, add(pVk, 32))))

                // gamma2
                mstore(add(_pPairing, 448), gammax1)
                mstore(add(_pPairing, 480), gammax2)
                mstore(add(_pPairing, 512), gammay1)
                mstore(add(_pPairing, 544), gammay2)

                // C
                mstore(add(_pPairing, 576), calldataload(pC))
                mstore(add(_pPairing, 608), calldataload(add(pC, 32)))

                // delta2
                mstore(add(_pPairing, 640), deltax1)
                mstore(add(_pPairing, 672), deltax2)
                mstore(add(_pPairing, 704), deltay1)
                mstore(add(_pPairing, 736), deltay2)

                let success := staticcall(sub(gas(), 2000), 8, _pPairing, 768, _pPairing, 0x20)

                isOk := and(success, mload(_pPairing))
            }

            let pMem := mload(0x40)
            mstore(0x40, add(pMem, pLastMem))

            // Validate that all evaluations ∈ F

            checkField(calldataload(add(_pubSignals, 0)))

            checkField(calldataload(add(_pubSignals, 32)))

            checkField(calldataload(add(_pubSignals, 64)))

            checkField(calldataload(add(_pubSignals, 96)))

            checkField(calldataload(add(_pubSignals, 128)))

            checkField(calldataload(add(_pubSignals, 160)))

            checkField(calldataload(add(_pubSignals, 192)))

            checkField(calldataload(add(_pubSignals, 224)))

            checkField(calldataload(add(_pubSignals, 256)))

            checkField(calldataload(add(_pubSignals, 288)))

            checkField(calldataload(add(_pubSignals, 320)))

            checkField(calldataload(add(_pubSignals, 352)))

            checkField(calldataload(add(_pubSignals, 384)))

            checkField(calldataload(add(_pubSignals, 416)))

            checkField(calldataload(add(_pubSignals, 448)))

            checkField(calldataload(add(_pubSignals, 480)))

            checkField(calldataload(add(_pubSignals, 512)))

            checkField(calldataload(add(_pubSignals, 544)))

            checkField(calldataload(add(_pubSignals, 576)))

            checkField(calldataload(add(_pubSignals, 608)))

            checkField(calldataload(add(_pubSignals, 640)))

            checkField(calldataload(add(_pubSignals, 672)))

            checkField(calldataload(add(_pubSignals, 704)))

            checkField(calldataload(add(_pubSignals, 736)))

            checkField(calldataload(add(_pubSignals, 768)))

            // Validate all evaluations
            let isValid := checkPairing(_pA, _pB, _pC, _pubSignals, pMem)

            mstore(0, isValid)
            return(0, 0x20)
        }
    }
}
