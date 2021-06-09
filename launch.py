from PyQt5 import QtWidgets
from autocam import autocam_ui
import sys

# Function Main Start
def main():
    app = QtWidgets.QApplication(sys.argv)
    window = autocam_ui()
    window.show()
    sys.exit(app.exec_())
# Funtion Main End

if __name__ == '__main__':
    main() 