Installation
============

0. Install Perl if not installed. For example to **C:\Perl**
1. Install MinGW if not installed. For example to **C:\MinGW**
2. Open Windows Command Processor (Admin mode) and run to create association (do not forget to change path to **perl.exe**)
    
    ```
    assoc .perl=Perl.File
    ftype Perl.File=C:\Strawberry\perl\bin\perl.exe "%1" %* 
    ```

3. Define correct path of GCOV executable in **geninfo.perl**:
      
    ```
    our $gcov_tool = "C:\\CORRECT_PATH_TO\\gcov.exe";
    ```