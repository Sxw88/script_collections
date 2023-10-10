import pikepdf
import easygui

pdf_loc = easygui.fileopenbox(title="Open File",default="*.pdf",filetypes=["*.pdf"])
print("File location:")
print(pdf_loc)
pdf_pass = input("PDF password: ")

pdf = pikepdf.open(pdf_loc, password=pdf_pass)

print("\nProcessing...\n")
print("Save File As : \n")

pdf_loc2 = easygui.filesavebox(title="Save File",default="*.pdf",filetypes=["*.pdf"])
pdf.save(pdf_loc2)

print("The password has been successfully removed from the PDF")
print("\aLocation: " + pdf_loc2)

input("Press Enter to continue...")
