from PyQt5 import QtWidgets, uic, QtCore, QtGui, QtWidgets
from PyQt5.QtGui import QPixmap
from PyQt5.QtWidgets import QPushButton, QLabel, QFileDialog
from PyQt5.QtCore import QDir
import sys
import ctypes
import os

CP_console = "cp" + str(ctypes.cdll.kernel32.GetConsoleOutputCP())
local_pp = os.path.abspath("")
gui_path = local_pp + "/qtgui/fbm_auto_gui_eng.ui" 
save_file_path = "./qtgui/gui.cfg"

class autocam_ui(QtWidgets.QMainWindow):
    def __init__(self):
        super(autocam_ui, self).__init__() # Call the inherited classes __init__ method
        uic.loadUi(gui_path, self)
        self.b_states = [] # empty list for button states values
        #self.setFixedSize(721, 806) # turn off window resizing
        self.toolButtonSelectModel.clicked.connect(self.get_model_file_name) # Set action to Get Model File Name
        self.toolButtonSelectToolList.clicked.connect(self.get_tool_list_name) # Set action to Get Tool List File
        self.ButtonNXDirectory.clicked.connect(self.get_nx_directory) # Set NX Installation Folder
        self.ButtonSelectExportDat.clicked.connect(self.get_dat_convertation) # Set .dat file to convert
        self.ButtonSelectExportXL.clicked.connect(self.get_xl_convertation) # Set .xlsx file to convert
        self.read_save_file()

        self.lineNXPath.textChanged.connect(self.process_lineEdit) # Check if Proccess button can be enabled after editing NX Path...
        self.lineEditModel.textChanged.connect(self.process_lineEdit) # ... or Model path ...
        self.lineEditToolList.textChanged.connect(self.process_lineEdit) # ... or Tool List Path
        self.lineEditExportDat.textChanged.connect(self.convertDat_lineEdit) # Check if Convert .dat button can be enabled
        self.lineEditExportXL.textChanged.connect(self.convertXL_lineEdit) # Check if Convert .xlsx button can be enabled

        self.ButtonConvertDat.clicked.connect(self.dat_to_xl_convertaion) # Action on Convert .dat button click
        self.ButtonConvertXL.clicked.connect(self.xl_to_dat_convertaion) # Action on Convert .xlsx button click
        self.ButtonProcess.clicked.connect(self.start_process) # Action on Proccess button click
        self.ButtonFeaturesOperations.clicked.connect(self.open_features_operations) # Open features_operations.xlsx file
        
        self.process = QtCore.QProcess(self) # QProcess object for external app
        self.process.readyRead.connect(self.dataReady) # QProcess emits `readyRead` when there is data to be read

        self.process.started.connect(lambda: self.turn_off_buttons()) # Just to prevent accidentally running multiple times
        self.process.finished.connect(lambda: self.set_states())      # Disable the button when process starts, and enable it when it finishes

        #self.show()

    #def __del__(self):
        #sys.stdout = sys.__stdout__
    
    def dataReady(self):
        cursor = self.textEdit.textCursor()
        cursor.movePosition(cursor.End)
        
        # Here we have to decode the QByteArray
        info_text = str(self.process.readAllStandardOutput().data().decode(CP_console))
        error_text = str(self.process.readAllStandardError().data().decode(CP_console))
        if info_text:
            cursor.insertText(info_text)
        if error_text:
            cursor.insertText(error_text)
        #cursor.insertText(str(self.process.readAll().data().decode(CP_console)))
        self.textEdit.ensureCursorVisible()    

    def get_model_file_name(self): # Model Selection Dialog
        dialog = QFileDialog(None, "Select Model File", None, "NX Models (*.prt)")
        dialog.setFileMode(QFileDialog.AnyFile)
        dialog.setFilter(QDir.Files)

        if dialog.exec_():
            model_file_name = dialog.selectedFiles()

            if model_file_name[0].endswith('.prt'):
                self.lineEditModel.setText(str(model_file_name[0]))
                
    def get_tool_list_name(self): # Tool List Selection Dialog
        dialog = QFileDialog(None, "Select Excel Tool List File", local_pp+"/spreadsheets", "Excel Sheet (*.xlsx)")
        dialog.setFileMode(QFileDialog.AnyFile)
        dialog.setFilter(QDir.Files)

        if dialog.exec_():
            tool_list_name = dialog.selectedFiles()

            if tool_list_name[0].endswith('.xlsx'):
                self.lineEditToolList.setText(str(tool_list_name[0]))

    def get_nx_directory(self): # NX Installation Folder Selection Dialog
        dialog = QFileDialog.getExistingDirectory(None, "Select NX Isntallation Directory","C:\\")
        if dialog != "":
            if dialog.endswith("/"):
                self.lineNXPath.setText(str(dialog))
            else: 
                dialog = str(dialog)+"/"
                self.lineNXPath.setText(str(dialog))

    def get_dat_convertation(self): # .dat File Selection Dialog
        dialog = QFileDialog(None, "Select .dat file to convert", local_pp, "Tool Database (*.dat)" )
        dialog.setFileMode(QFileDialog.AnyFile)
        dialog.setFilter(QDir.Files)

        if dialog.exec_():
            datFile = dialog.selectedFiles()

            if datFile[0].endswith('.dat'):
                self.lineEditExportDat.setText(str(datFile[0]))

    def get_xl_convertation(self): # .xlsx File Selection Dialog
        dialog = QFileDialog(None, "Select .xlsx file to convert", local_pp+"/spreadsheets", "Excel Sheet (*.xlsx)")
        dialog.setFileMode(QFileDialog.AnyFile)
        dialog.setFilter(QDir.Files)

        if dialog.exec_():
            XLFile = dialog.selectedFiles()

            if XLFile[0].endswith('.xlsx'):
                self.lineEditExportXL.setText(str(XLFile[0]))

    def process_lineEdit(self): # Check if three lines filled with infomation to acess process button
        if self.lineNXPath.text() and self.lineEditModel.text() and self.lineEditToolList.text():
            self.ButtonProcess.setEnabled(True)
        else: 
            self.ButtonProcess.setEnabled(False)

    def convertDat_lineEdit(self): # Check access to .dat converter
        if self.lineEditExportDat.text():
            self.ButtonConvertDat.setEnabled(True)
        else: 
            self.ButtonConvertDat.setEnabled(False)

    def convertXL_lineEdit(self): # Check access to .xlsx converter
        if self.lineEditExportXL.text():
            self.ButtonConvertXL.setEnabled(True)
        else: 
            self.ButtonConvertXL.setEnabled(False)

    def dat_to_xl_convertaion(self): # Action on .dat to .xlsx convertation 
        dat_file_path = str(self.lineEditExportDat.text())
        self.ButtonConvertDat.setEnabled(False)
        self.lineEditExportDat.setText("")
        self.process.start("python.exe", ["./scripts/convert_tool_list/convert_dat_to_excel.py", dat_file_path])
        os.system('start explorer.exe "' + str(local_pp) + '\\spreadsheets"')
        
    def xl_to_dat_convertaion(self): # Action on .xlsx to .dat convertation 
        excel_file_path = str(self.lineEditExportXL.text())
        self.ButtonConvertXL.setEnabled(False)
        self.lineEditExportXL.setText("")
        self.process.start("python.exe", ["./scripts/convert_tool_list/convert_excel_to_dat.py", excel_file_path])
        os.system('start explorer.exe "' + str(local_pp) + '\\spreadsheets"')

    def start_process(self): # Action when "Process" button is clicked
        model_path = str(self.lineEditModel.text())
        excel_tool_file_path = str(self.lineEditToolList.text())
        nx_path = str(self.lineNXPath.text())
        #self.process.start("cmd.exe /C start " + str(local_pp) +"/scripts/runner_main/main.py \"" + str(model_path) + "\" \"" + str(excel_tool_file_path) + "\" \"" + str(nx_path)+"\"")
        #print("cmd.exe /C start " + str(local_pp) +"/scripts/runner_main/main.py \"" + str(model_path) + "\" \"" + str(excel_tool_file_path) + "\" \"" + str(nx_path)+"\"")
        self.process.start("python.exe", ["./scripts/runner_main/main.py", model_path, excel_tool_file_path, nx_path])
    
    def set_states(self): # Set button states after finisihing process
        if self.b_states[0] == 1:
            self.ButtonConvertDat.setEnabled(True)
        else:
            self.ButtonConvertDat.setEnabled(False)
        
        if self.b_states[1] == 1:
            self.ButtonConvertXL.setEnabled(True)
        else:
            self.ButtonConvertXL.setEnabled(False)
        
        if self.b_states[2] == 1:
            self.ButtonProcess.setEnabled(True)
        else:
            self.ButtonProcess.setEnabled(False)

    def turn_off_buttons(self): # Turn off buttons after starting process
        self.b_states = []
        if  self.ButtonConvertDat.isEnabled():
            self.b_states.append(1)
        else:
            self.b_states.append(0)

        if  self.ButtonConvertXL.isEnabled():
            self.b_states.append(1)
        else:
            self.b_states.append(0)

        if  self.ButtonProcess.isEnabled():
            self.b_states.append(1)
        else:
            self.b_states.append(0)

        self.ButtonConvertDat.setEnabled(False)
        self.ButtonConvertXL.setEnabled(False)
        self.ButtonProcess.setEnabled(False)        

    def read_save_file(self): # read saved path to object at each program startup
        try:
            with open(save_file_path, 'r+') as file:
                saved_text = file.read().split('\n')
            for x in range(len(saved_text)):  
                if 'tool_list_path' in saved_text[x]: # read row with saved tool path list value
                    line = saved_text[x]
                    line = line.split(' = ')
                    line = line[1]
                    saved_tool_list_path = line 
                    self.lineEditToolList.setText(str(saved_tool_list_path))
                if 'nx_path'in saved_text[x]: # read row with saved Nx path value
                    line = saved_text[x]
                    line = line.split(' = ')
                    line = line[1]
                    saved_nx_path = line
                    self.lineNXPath.setText(str(saved_nx_path)) # Set Default NX directory at startup of program
        except:
            pass
    
    def closeEvent(self, event): # Action on closing the application
        widgetList = QtWidgets.QApplication.topLevelWidgets()
        numWindows = len(widgetList)
        if numWindows > 1:
            event.ignore()
        else:
            data = ''
            with open(save_file_path, 'w') as file:
                a = "# This file stores saved path to NX and Tool list\n"
                b = str(self.lineEditToolList.text())
                c = str(self.lineNXPath.text())
                data += a + '\n'
                data +='tool_list_path = ' + b + '\n'
                data +='nx_path = ' + c + '\n'
                file.write(data)
            event.accept()
    
    def open_features_operations(self): # Action on Features Operations button pressed
        os.chdir('.\\spreadsheets')
        os.system('start excel.exe '+str(local_pp)+'\\spreadsheets\\features_operations.xlsx')
        os.chdir(str(local_pp))
"""
# Function Main Start
def main():
    app = QtWidgets.QApplication(sys.argv)
    window = FBM_GUI()
    window.show()
    sys.exit(app.exec_())
# Funtion Main End

if __name__ == '__main__':
    main() 
"""