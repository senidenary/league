import QtQuick 2.7
import QtQuick.Controls 1.4
import QtQuick.LocalStorage 2.0
import QtQuick.Window 2.2

import "window-components"

Window {
	id: insertWindow
	width: 452
	height: 182
	title: qsTr("League - Insert New Game")
	modality: Qt.ApplicationModal
	color: "white"

	Window {
		id: calendarWindow
		width: 400
		height: calendar.height
		visible: false
		title: qsTr("Select Date")

		Calendar {
			id: calendar
			anchors {
				top: parent.top
				left: parent.left
				right: parent.right
			}

			onSelectedDateChanged: updateDateButton()
			onDoubleClicked: calendarWindow.visible = false

			function updateDateButton() {
				dateButton.text =
						selectedDate.toLocaleDateString(Qt.locale("en_US"), "yyyy'.'MM'.'dd")
			}

			Component.onCompleted: updateDateButton()
		}
	}

	Row {
		id: topRow
		height: 50
		anchors {
			top: parent.top
			horizontalCenter: parent.horizontalCenter
		}
		spacing: 5

		Label {
			anchors.verticalCenter: parent.verticalCenter
			text: qsTr("Date:")
		}

		Button {
			id: dateButton
			anchors.verticalCenter: parent.verticalCenter

			onClicked: calendarWindow.show()
		}

		Separator {
			height: topRow.height - 20
			anchors.verticalCenter: parent.verticalCenter
		}

		Button {
			anchors.verticalCenter: parent.verticalCenter
			text: qsTr("Add Game")

			onClicked: { //TODO: Feedback that game was added
				var db = LocalStorage.openDatabaseSync(dbName, dbVer, dbDesc, dbEstSize)

				db.transaction(
					function(tx) {
						var penaltiesData = "null, null"
						if (playerEntryColumnA.penalties || playerEntryColumnB.penalties) {
							penaltiesData = playerEntryColumnA.penalties + ', ' +
									playerEntryColumnB.penalties
						}

						var x = 'INSERT INTO Games (date,
									player_one, player_two,
									team_one, team_two,
									goals_one, goals_two,
									penalties_one, penalties_two) VALUES (' +
								'"' + dateButton.text + '", ' +
								playerEntryColumnA.getSelectedPlayer().id + ', ' +
								playerEntryColumnB.getSelectedPlayer().id + ', ' +
								playerEntryColumnA.getSelectedTeam().id + ', ' +
								playerEntryColumnB.getSelectedTeam().id + ', ' +
								playerEntryColumnA.goals + ', ' +
								playerEntryColumnB.goals + ', ' +
								penaltiesData + ')'
						tx.executeSql(x);
					}
				)
			}
		}
	}

	Row {
		anchors {
			top: topRow.bottom
			left: parent.left
			right: parent.right
			bottom: parent.bottom
		}

		PlayerEntryColumn {
			id: playerEntryColumnA
		}

		Separator {
			height: parent.height - 20
			anchors.verticalCenter: parent.verticalCenter
		}

		PlayerEntryColumn {
			id: playerEntryColumnB
		}

		Separator {
			height: parent.height - 20
			anchors.verticalCenter: parent.verticalCenter
		}

		Column {
			id: addingColumn
			padding: 5
			spacing: 5

			signal newPlayer
			onNewPlayer: {
				newDataInput.accepted.disconnect(newPlayer)
				insertNewData('Players', newDataInput.text);
				playerEntryColumnA.updateNames()
				playerEntryColumnB.updateNames()
			}

			signal newTeam
			onNewTeam: {
				newDataInput.accepted.disconnect(newTeam)
				insertNewData('Teams', newDataInput.text);
				playerEntryColumnA.updateTeams()
				playerEntryColumnB.updateTeams()
			}

			function insertNewData(table, data) {
				var db = LocalStorage.openDatabaseSync(dbName, dbVer, dbDesc, dbEstSize)

				db.transaction(
					function(tx) {
						//TODO: fix obvious SQL injection
						tx.executeSql('INSERT INTO ' + table + ' (name) VALUES ("' + data + '")');
					}
				)
				newDataWindow.visible = false
			}

			function updateDataEntryWindow(type, callback) {
				newDataWindow.visible = true
				newDataWindow.title = qsTr("Enter New " + type + " Name")
				newDataInput.accepted.connect(callback)
			}

			Button {
				id: newNameButton
				width: 30
				text: "+"

				onClicked: addingColumn.updateDataEntryWindow("Player", addingColumn.newPlayer)
			}

			Button {
				id: newTeamButton
				width: 30
				text: "+"

				onClicked: addingColumn.updateDataEntryWindow("Team", addingColumn.newTeam)
			}

			Window {
				id: newDataWindow
				width: 250
				height: 25
				visible: false
				modality: Qt.ApplicationModal

				onVisibleChanged: if (visible) { newDataInput.text = '' }

				TextField {
					id: newDataInput
					anchors.fill: parent
					focus: true
				}
			}
		}
	}
}
