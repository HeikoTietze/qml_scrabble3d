import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Dialog {
    id: newgame
    title: qsTr("Start a new game")
    standardButtons: Dialog.Cancel | Dialog.Ok
    modal: true

    x: (app.width - newgame.width) / 2
    y: (app.height - newgame.height) / 2

    property int rbIndex: 1

    ListModel {
        id: playerNames
        dynamicRoles: true
    }
    onAboutToShow: {
        var configData = {}
        configData = GamePlay.loadConfig("")
        rbIndex = configData["playerCount"] || 1
        playerNames.clear()
        playerNames.append({"playerName": configData["player1"] || qsTr("1st Player"),
                               "isChecked": rbIndex === 1,
                               "isComputer": false})
        playerNames.append({"playerName": configData["player2"] || qsTr("2nd Player"),
                               "isChecked": rbIndex === 2,
                               "isComputer": configData["comp2"] === "true" || false})
        playerNames.append({"playerName": configData["player3"] || qsTr("3rd Player"),
                               "isChecked": rbIndex === 3,
                               "isComputer": configData["comp3"] === "true" || false})
        playerNames.append({"playerName": configData["player4"] || qsTr("4th Player"),
                               "isChecked": rbIndex === 4,
                               "isComputer": configData["comp4"] === "true" || false})
        cbRandomized.checked = configData["randomized"] === "true" || false
        newgame.focus = true
    }

    function getTimeString() {
        var aTime = new Date(0,0,0,0,0,0)
        aTime.setSeconds(config.timeControlValue)
        return aTime.toTimeString()
    }
    contentItem: FocusScope {
        id: focus //required to receive return key
        Keys.onReturnPressed: accept()
        focus: standardButton(Dialog.Ok)
        ButtonGroup { id: radioGroup }
        Component {
            id: playerDelegate
            RowLayout {
                id: layout
                spacing: 3
                RadioButton {
                    id: rbPlayerCount
                    text: (index + 1)
                    checked: isChecked
                    onCheckedChanged: rbIndex = index + 1
                    ButtonGroup.group: radioGroup
                    Layout.alignment: Qt.AlignTop
                }
                ColumnLayout {
                    spacing: 1
                    TextField   {
                        id: tiName
                        implicitWidth: 100
                        text: playerName
                        enabled: (rbIndex > index) && (!cbComputer.checked)
                        background: Rectangle {
                            color: tiName.enabled
                                   ? (tiName.text === "Computer")
                                     ? "red" : config.myPalette.base
                            : config.myPalette.mid
                        }
                            leftPadding: 2
                            verticalAlignment: Qt.AlignVCenter
                            mouseSelectionMode: TextInput.SelectWords
                            selectByMouse: true
                            onFocusChanged:
                                if (focus) selectAll()
                            onEditingFinished:
                                if (text !== "Computer")
                                    playerNames.setProperty(index,"playerName",text)
                        }
                        CheckBox {
                            id: cbComputer
                            text: "Computer"
                            checked: isComputer
                            onClicked: playerNames.setProperty(index,"isComputer",checked)
                            visible: index > 0 //at least one human player should be in the game
                            enabled: (rbIndex > index)
                        }
                    }
                }
            }
        RowLayout {
            id: configInfo
            spacing: 6
            ColumnLayout {
                id: pnLeft
                spacing: 12
                Layout.leftMargin: 12
                RowLayout {
                    id: header
                    Label  {
                        leftPadding: 25 //~ width(radiobutton) + spacing
                        text: "#"
                        font.bold: true
                    }
                    Label {
                        text: qsTr("player name")
                        font.bold: true
                    }
                }
                Repeater {
                    model: playerNames
                    delegate: playerDelegate
                }
                CheckBox {
                    id: cbRandomized
                    text: "Randomized order"
                    focus: false
                }
            }
            GridLayout {
                id: pnRight
                columns: 2
                rowSpacing: 6
                Layout.alignment: Qt.AlignTop
                Layout.rightMargin: 24
                Layout.leftMargin: 24
                Label { Layout.columnSpan: 2; text: qsTr("Settings:"); font.bold: true }
                Label { text: qsTr("Board:")} Label { text: config.boardName }
                Label { text: qsTr("Letters:") } Label { text: config.lettersetName }
                Label { text: qsTr("Dictionary:") } Label { text: config.dictionaryName }
                Label { text: qsTr("Time control:") }
                Label { text: config.timeControl == 0
                              ? qsTr("No time control")
                              : config.timeControl == 1
                                ? qsTr("Per Move") + " (" + getTimeString() + ")"
                                : qsTr("Per Game") + " (" + getTimeString() + ")"
                }
            }
        }
    }

    function getNames() {
        let sRet = []
        for (var i=0; i<rbIndex; i++)
            if (playerNames.get(i).isComputer)
                sRet.push("Computer")
            else
                sRet.push(playerNames.get(i).playerName)
        return sRet
    }
    onAccepted: {
        var excludedCategoryList = [];
        var letterlist = [];
        for (var i=0; i<config.letterSet.rowCount; i++) {
            letterlist.push(config.letterSet.getRow(i).letter);
            letterlist.push(config.letterSet.getRow(i).value);
            letterlist.push(config.letterSet.getRow(i).count);
        }

        GamePlay.startNewGame(getNames(),                             //PlayerNames
                              config.numberOfLettersOnRack,           //RackSize
                              config.bIs3D,                           //is3D
                              config.board,                           //FieldTypeArray
                              letterlist,                             //LetterList
                              config.numberOfJokers,                  //NumberOfJokers
                              true,                                   //CanJokerExchange
                              50,                                     //GameEndBonus
                              config.numberOfPasses,                  //NumberOfPasses
                              10,                                     //JokerPenalty
                              true,                                   //ChangeIsPass
                              config.timeControl,                     //TimeControl
                              config.timeControlValue,                //TimeControlValue
                              3,                                      //LimitedExchange
                              false,                                  //CambioSecco
                              false,                                  //Whatif
                              true,                                   //Add
                              true,                                   //Substract
                              0,                                      //TimePenaltyValue
                              10,                                     //TimePenaltyCount
                              true,                                   //TimeGameLost
                              0,                                      //WordCheck
                              30,                                     //WordCheckPeriod
                              10,                                     //WordCheckPenlty
                              10,                                     //WordCheckBonus
                              config.bingoBonus,                      //ScrabbleBonus
                              false,                                  //isCLABBERS
                              cbRandomized.checked);                  //RandomSequence

        main.board.jokerPicker.updatePickerModel() //use current letterlist for joker picker
        main.board.updateLabelsModel() //redraw labels on x/y axis
        main.board.updateFieldSize() //changing the number of fields should result in resizing
        if (config.bIs3D) main.cube.updateCubeModel()

        var configData = {}
        configData = GamePlay.loadConfig("")
        configData["player1"] = playerNames.get(0).playerName
        configData["player2"] = playerNames.get(1).playerName
        configData["player3"] = playerNames.get(2).playerName
        configData["player4"] = playerNames.get(3).playerName
        configData["comp1"] = playerNames.get(0).isComputer
        configData["comp2"] = playerNames.get(1).isComputer
        configData["comp3"] = playerNames.get(2).isComputer
        configData["comp4"] = playerNames.get(3).isComputer
        configData["playerCount"] = rbIndex
        configData["randomized"] = cbRandomized.checked
        GamePlay.saveConfig("", configData)

        config.saveConfig( "" )
    }
}
