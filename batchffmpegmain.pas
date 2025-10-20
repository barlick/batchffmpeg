unit batchffmpegmain;

{$mode objfpc}{$H+}

interface

uses
 Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, ExtCtrls,
 ComCtrls, lazfileutils, process, unix, FileUtil;

type

 { Tbatchffpmegmainform }

 Tbatchffpmegmainform = class(TForm)
  RefreshButton: TButton;
  DeSelectAllButton: TButton;
  StatusMemo: TMemo;
  SelectAllButton: TButton;
  DeleteSourceFilesAfterSuccessfulTranscodeCheckBox: TCheckBox;
  FFMpegParametersEdit: TEdit;
  Label5: TLabel;
  TargetFileTypeComboBox: TComboBox;
  ListView1: TListView;
  SelectDirectoryDialog1: TSelectDirectoryDialog;
  SourceFolderBrowseButton: TButton;
  TargetFolderBrowseButton: TButton;
  SourceImageFileTypesEdit: TEdit;
  SourceFolderEdit: TEdit;
  TargetFolderEdit: TEdit;
  Label1: TLabel;
  Label2: TLabel;
  Label3: TLabel;
  Label4: TLabel;
  StartButton: TButton;
  Panel1: TPanel;
  Panel2: TPanel;
  Panel3: TPanel;
  procedure DeSelectAllButtonClick(Sender: TObject);
  procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
  procedure FormShow(Sender: TObject);
  procedure RefreshButtonClick(Sender: TObject);
  procedure SelectAllButtonClick(Sender: TObject);
  procedure SourceFolderBrowseButtonClick(Sender: TObject);
  procedure SourceFolderEditEnter(Sender: TObject);
  procedure SourceFolderEditExit(Sender: TObject);
  procedure SourceImageFileTypesEditEnter(Sender: TObject);
  procedure SourceImageFileTypesEditExit(Sender: TObject);
  procedure StartButtonClick(Sender: TObject);
  procedure TargetFileTypeComboBoxChange(Sender: TObject);
  procedure TargetFolderBrowseButtonClick(Sender: TObject);
  procedure dodisablecontrols;
  procedure doenablecontrols;
  procedure scanforfiles;
  function fn_FFMpegParametersValid(FFMpegParameters : string) : boolean;
  function fn_start_ffmpeg_instance_to_process_file(sourcepath,sourcefilename,targetpath,targetfileextension,FFMpegParameters : string) : boolean;
  procedure save_config;
  procedure load_config;
 private
  factive : boolean;
  presSourceImageFileTypesEditText : string;
  presSourceFolderEditText : string;
 public

 end;

var
 batchffpmegmainform: Tbatchffpmegmainform;

implementation

{$R *.lfm}

{ Tbatchffpmegmainform }

procedure Tbatchffpmegmainform.save_config;
var
 f : textfile;
 configfilename : string;
begin
 configfilename := GetUserDir;
 configfilename := AppendPathDelim(configfilename);
 configfilename := configfilename + '.config/batchffmpeg.conf';
 assignfile(f,configfilename);
 rewrite(f);
 if ioresult = 0 then
  begin
   writeln(f,'batchffmpeg config file.');
   writeln(f,'SourceImageFileTypes:'+SourceImageFileTypesEdit.text);
   writeln(f,'SourceFolder:'+SourceFolderEdit.text);
   writeln(f,'TargetFileType:'+inttostr(TargetFileTypeComboBox.itemindex));
   writeln(f,'TargetFolder:'+TargetFolderEdit.text);
   if DeleteSourceFilesAfterSuccessfulTranscodeCheckBox.checked then
    begin
     writeln(f,'DeleteSourceFilesAfterSuccessfulTranscode:Y');
    end
    else
    begin
     writeln(f,'DeleteSourceFilesAfterSuccessfulTranscode:N');
    end;
   writeln(f,'FFMpegParameters:'+FFMpegParametersEdit.text);
  end;
 closefile(f);
 if ioresult = 0 then begin end;
end;

procedure Tbatchffpmegmainform.load_config;
var
 f : textfile;
 configfilename,s : string;
begin
 configfilename := GetUserDir;
 configfilename := AppendPathDelim(configfilename);
 configfilename := configfilename + '.config/batchffmpeg.conf';
 if fileexists(configfilename) then
  begin
   assignfile(f,configfilename);
   reset(f);
   if ioresult = 0 then
    begin
     readln(f,s); // batchffmpeg config file.
     readln(f,s); if pos('SOURCEIMAGEFILETYPES:',uppercase(s)) > 0 then begin s := stringreplace(s,'SourceImageFileTypes:','',[rfreplaceall,rfignorecase]); s := trim(trimleft(s)); SourceImageFileTypesEdit.text := s; end;
     readln(f,s); if pos('SOURCEFOLDER:',uppercase(s)) > 0 then begin s := stringreplace(s,'SourceFolder:','',[rfreplaceall,rfignorecase]); s := trim(trimleft(s)); SourceFolderEdit.text := s; end;
     readln(f,s); if pos('TARGETFILETYPE:',uppercase(s)) > 0 then begin s := stringreplace(s,'TargetFileType:','',[rfreplaceall,rfignorecase]); s := trim(trimleft(s)); TargetFileTypeCombobox.itemindex := strtoint(s); end;
     readln(f,s); if pos('TARGETFOLDER:',uppercase(s)) > 0 then begin s := stringreplace(s,'TargetFolder:','',[rfreplaceall,rfignorecase]); s := trim(trimleft(s)); targetFolderEdit.text := s; end;
     readln(f,s); if pos('DELETESOURCEFILESAFTERSUCCESSFULTRANSCODE:',uppercase(s)) > 0 then
      begin
       s := stringreplace(s,'DeleteSourceFilesAfterSuccessfulTranscode:','',[rfreplaceall,rfignorecase]); s := trim(trimleft(s));
       if uppercase(s) = 'Y' then DeleteSourceFilesAfterSuccessfulTranscodeCheckbox.checked := true else DeleteSourceFilesAfterSuccessfulTranscodeCheckbox.checked := false;
      end;
     readln(f,s); if pos('FFMPEGPARAMETERS:',uppercase(s)) > 0 then begin s := stringreplace(s,'FFMpegParameters:','',[rfreplaceall,rfignorecase]); s := trim(trimleft(s)); FFMpegParametersEdit.text := s; end;
    end;
   closefile(f);
   if ioresult = 0 then begin end;
  end;
end;

procedure Tbatchffpmegmainform.dodisablecontrols;
begin
 panel1.enabled := false;
 panel2.enabled := false;
 panel3.enabled := false;
end;

procedure Tbatchffpmegmainform.doenablecontrols;
begin
 panel1.enabled := true;
 panel2.enabled := true;
 panel3.enabled := true;
end;

procedure Tbatchffpmegmainform.scanforfiles;
var
 item: TListItem;
 dirts : TSearchrec;
 validfileextensions,thisfileextension,TargetFileType : string;
 searchfilenames : TStringlist;
 ct : integer;
begin
 dodisablecontrols;
 try
  searchfilenames := TStringList.create;
  searchfilenames.clear;
  ListView1.Items.clear;
  validfileextensions := uppercase(SourceImageFileTypesEdit.Text);
  TargetFileType := TargetFileTypeComboBox.Items[TargetFileTypeComboBox.itemindex];
  TargetFileType := uppercase(TargetFileType);
  if trim(trimleft(SourceFolderEdit.text)) <> '' then
   begin
    if  directoryexists(AppendPathDelim(SourceFolderEdit.text)) then
     begin
      if findfirst(AppendPathDelim(SourceFolderEdit.text)+'*',faAnyFile,dirts) = 0 then
       begin
        repeat
         if (dirts.Attr and faDirectory) <> faDirectory then
          begin
           if dirts.Name <> '' then
            begin
             thisfileextension := uppercase(ExtractFileExt(dirts.Name));
             thisfileextension := StringReplace(thisfileextension,'.','',[rfreplaceall]);
             if (pos(thisfileextension,uppercase(validfileextensions)+';') > 0) or
                (pos(thisfileextension,'.'+uppercase(validfileextensions)) > 0) or
                (pos(thisfileextension,';'+uppercase(validfileextensions)) > 0) or
                (pos(thisfileextension,uppercase(validfileextensions)+',') > 0) or
                (pos(thisfileextension,','+uppercase(validfileextensions)) > 0) then
              begin
               if pos(TargetFileType,thisfileextension) = 0 then
                 begin
                  searchfilenames.add(dirts.Name);
                  //item := ListView1.Items.Add;
                  //item.Caption := dirts.Name;
                 end;
              end;
            end;
          end;
        until FindNext(dirts) <> 0;
       end;
      FindClose(dirts);
      searchfilenames.sorted := true;
      if searchfilenames.count > 0 then
       begin
        ct := 0;
        while ct < searchfilenames.count do
         begin
          item := ListView1.Items.Add;
          item.Caption := searchfilenames[ct];
          inc(ct);
         end;
       end;
     end;
   end;
 finally
  doenablecontrols;
  searchfilenames.clear;
  searchfilenames.free;
 end;
end;

procedure Tbatchffpmegmainform.TargetFileTypeComboBoxChange(Sender: TObject);
begin
 if factive then
  begin
   scanforfiles;
  end;
end;

procedure Tbatchffpmegmainform.TargetFolderBrowseButtonClick(Sender: TObject);
var
  seldir : string;
begin
 if selectdirectory('Select Target Folder for Converted Video Files','~',seldir,TRUE,0) then
 if seldir <> '' then
 //if selectdirectorydialog1.Execute then
  begin
   TargetFolderEdit.text := seldir; // selectdirectorydialog1.FileName;
  end;
end;

procedure Tbatchffpmegmainform.SourceFolderBrowseButtonClick(Sender: TObject);
var
 seldir : string;
begin
 if selectdirectory('Select Source Video Files Folder','~',seldir,TRUE,0) then
 //if selectdirectorydialog1.Execute then
 if seldir <> '' then
  begin
   if AppendPathDelim(TargetFolderEdit.text) = AppendPathDelim(SourceFolderEdit.text) then
     begin
      TargetFolderEdit.text := '';
     end;
   factive := false;
   SourceFolderEdit.text := seldir; //selectdirectorydialog1.FileName;
   factive := true;
   if TargetFolderEdit.text = '' then
    begin
     TargetFolderEdit.text := SourceFolderEdit.text;
    end;
   scanforfiles;
  end;
end;

procedure Tbatchffpmegmainform.SourceFolderEditEnter(Sender: TObject);
begin
 if factive then
  begin
   presSourceFolderEditText := SourceFolderEdit.Text;
  end;
end;

procedure Tbatchffpmegmainform.SourceFolderEditExit(Sender: TObject);
begin
 if factive then
  begin
   if presSourceFolderEditText <> SourceFolderEdit.Text then
    begin
     scanforfiles;
    end;
  end;
end;

procedure Tbatchffpmegmainform.SourceImageFileTypesEditEnter(Sender: TObject);
begin
 if factive then
  begin
   presSourceImageFileTypesEditText := SourceImageFileTypesEdit.Text;
  end;
end;

procedure Tbatchffpmegmainform.SourceImageFileTypesEditExit(Sender: TObject);
begin
 if factive then
  begin
   if presSourceImageFileTypesEditText <> SourceImageFileTypesEdit.Text then
    begin
     scanforfiles;
    end;
  end;
end;

procedure Tbatchffpmegmainform.RefreshButtonClick(Sender: TObject);
begin
 if factive then
  begin
   scanforfiles;
  end;
end;

procedure Tbatchffpmegmainform.DeSelectAllButtonClick(Sender: TObject);
var
 item: TListItem;
 ct : integer;
begin
 if factive then
  begin
   if ListView1.Items.Count > 0 then
    begin
     ct := 0;
     while ct < ListView1.Items.Count do
      begin
       item := ListView1.Items[ct];
       item.Checked := false;
       inc(ct);
      end;
     Listview1.Refresh;
    end;
  end;
end;

procedure Tbatchffpmegmainform.SelectAllButtonClick(Sender: TObject);
var
 item: TListItem;
 ct : integer;
begin
 if factive then
  begin
   if ListView1.Items.Count > 0 then
    begin
     ct := 0;
     while ct < ListView1.Items.Count do
      begin
       item := ListView1.Items[ct];
       item.Checked := true;
       inc(ct);
      end;
     Listview1.Refresh;
    end;
  end;
end;

function Tbatchffpmegmainform.fn_FFMpegParametersValid(FFMpegParameters : string) : boolean;
begin
 result := true; // Assume OK.
 if trim(trimleft(FFMpegParameters)) = '' then
  begin
   result := false;
  end
  else if pos('<SOURCE FILE>',uppercase(FFMpegParameters)) = 0 then
  begin
   result := false;
  end
  else if pos('<TARGET FILE>',uppercase(FFMpegParameters)) = 0 then
  begin
   result := false;
  end;
end;

function Tbatchffpmegmainform.fn_start_ffmpeg_instance_to_process_file(sourcepath,sourcefilename,targetpath,targetfileextension,FFMpegParameters : string) : boolean;
var
 parsedFFMpegParameters,targetfilename : string;
 temp,temp1,tempsourcefile,temptargetfile,homedir : string;
 s : longint;
begin
 result := false;
 if directoryexists(sourcepath) and fileexists(sourcepath+sourcefilename) and directoryexists(targetpath) and (targetfileextension <> '') and (FFMpegParameters <> '') then
  begin
   homedir := GetUserDir;
   homedir := AppendPathDelim(homedir);

   parsedFFMpegParameters := FFMpegParameters;
   parsedFFMpegParameters := trim(trimleft(parsedFFMpegParameters));
   if uppercase(copy(parsedFFMpegParameters,1,6)) = 'FFMPEG' then
    begin
     parsedFFMpegParameters := copy(parsedFFMpegParameters,7,length(parsedFFMpegParameters));
    end;
   parsedFFMpegParameters := trim(trimleft(parsedFFMpegParameters));

   tempsourcefile := homedir+'Documents/batchffmpeg_temp'+ExtractFileExt(sourcefilename);
   CopyFile(sourcepath+sourcefilename,tempsourcefile);
   parsedFFMpegParameters := stringreplace(parsedFFMpegParameters,'<source file>',tempsourcefile,[rfignorecase,rfreplaceall]);

   targetfilename := ExtractFileNameWithoutExt(sourcefilename);
   targetfilename := targetpath + targetfilename + '.' + targetfileextension;
   if fileexists(targetfilename) then
    begin
     deletefile(targetfilename);
    end;
   if NOT fileexists(targetfilename) then
    begin
     temptargetfile := homedir+'Documents/batchffmpeg_temp.'+targetfileextension;
     if fileexists(temptargetfile) then
      begin
       deletefile(temptargetfile);
      end;
     parsedFFMpegParameters := stringreplace(parsedFFMpegParameters,'<target file>',temptargetfile,[rfignorecase,rfreplaceall]);

     temp := 'ffmpeg '+parsedFFMpegParameters;
     temp1 := chr(39);
     temp := stringreplace(temp,'"',temp1,[rfignorecase,rfreplaceall]);
     s := fpsystem(temp);

     if fileexists(temptargetfile) then
      begin
       copyfile(temptargetfile,targetfilename);
      end;

     if fileexists(temptargetfile) then deletefile(temptargetfile);
     if fileexists(tempsourcefile) then deletefile(tempsourcefile);

     if fileexists(targetfilename) then
      begin
       result := true;
       StatusMemo.Lines.Add('Completed conversion of '+sourcefilename+' to '+targetfilename+'. Exit code: '+inttostr(s));
       if DeleteSourceFilesAfterSuccessfulTranscodeCheckBox.Checked then
        begin
         // OK: Looks like this ffmpeg conversion worked and we have opted to "Delete Source Files After Successful Transcode" so delete the source file:
         if fileexists(sourcepath+sourcefilename) then
          begin
           deletefile(sourcepath+sourcefilename);
           StatusMemo.Lines.Add('Deleted source video file '+sourcefilename+'.');
          end;
        end;
      end
      else
      begin
       StatusMemo.Lines.Add('Error: Failed to convert '+sourcefilename+' to '+targetfilename+'. Exit code: '+inttostr(s));
      end;
    end
    else
    begin
     StatusMemo.Lines.Add('Error: Target file "'+targetfilename+'" already exists and was unable to delete it.');
    end;
  end;
end;

procedure Tbatchffpmegmainform.StartButtonClick(Sender: TObject);
var
 item: TListItem;
 ct,numfound,x : integer;
 s,sizgb : string;
 getout : boolean;
 totfilesize,thisfilesize,totfilesizedone : int64;
 onepc,percentdone,percentremaining : real;
 starttime,tottimetaken,timeremaining : TDateTime;
begin
 if factive then
  begin
   if ListView1.Items.Count > 0 then
    begin
     ct := 0; numfound := 0; totfilesize := 0;
     while ct < ListView1.Items.Count  do
      begin
       item := ListView1.Items[ct];
       if item.Checked then
        begin
         inc(numfound);
         totfilesize := totfilesize + FileSize(AppendPathDelim(sourcefolderedit.text)+item.caption);
        end;
       inc(ct);
      end;
     if (targetfolderedit.text <> '') then
      begin
       if directoryexists(AppendPathDelim(TargetFolderEdit.text)) then
        begin
         if fn_FFMpegParametersValid(FFMpegParametersEdit.text) then
          begin
           if numfound > 0 then
            begin
             try
               dodisablecontrols;
               panel2.enabled := true;
               Startbutton.Caption := 'Running';
               StatusMemo.clear;
               application.processmessages;
               starttime := now;
               totfilesizedone := 0;
               sizgb := trim(trimleft(floattostr(totfilesize/1073741824)));
               x := pos('.',sizgb);
               if x > 0 then sizgb := copy(sizgb,1,x+2); // To 2dp in GB please.
               sizgb := trim(trimleft(sizgb));
               s := 's'; if numfound = 1 then s := '';
               StatusMemo.Lines.Add('Process started. Converting '+inttostr(numfound)+' file'+s+'. Start time: '+datetimetostr(starttime)+ ' total selected file size: '+sizgb+'GB,');
               ct := 0; getout := false;
               while (ct < ListView1.Items.Count) and not getout  do
                begin
                 item := ListView1.Items[ct];
                 if item.Checked then
                  begin
                   StatusMemo.Lines.Add('Converting '+AppendPathDelim(sourcefolderedit.text)+item.caption+' via FFMpeg.');
                   application.processmessages;
                   thisfilesize := FileSize(AppendPathDelim(sourcefolderedit.text)+item.caption);
                   if NOT fn_start_ffmpeg_instance_to_process_file(AppendPathDelim(sourcefolderedit.text),item.caption,AppendPathDelim(targetfolderedit.text),TargetFileTypeComboBox.items[TargetFileTypeComboBox.itemindex],FFMpegParametersEdit.text) then
                    begin
                     getout := true;
                    end
                    else
                    begin
                     totfilesizedone := totfilesizedone + thisfilesize;
                     // OK, we know "starttime" and we know the total file size and the total of that file size that's been done so how long remaining?
                     onepc := totfilesize / 100;
                     if onepc <> 0 then
                      begin
                       percentdone := totfilesizedone / onepc;
                      end
                      else percentdone := 100;
                     tottimetaken := now - starttime;
                     // So it took "tottimetaken" (time) to do "percentdone" (%) so how much time did 1% take?
                     percentremaining := 100 - percentdone;
                     if percentremaining > 0 then
                      begin
                       timeremaining := (tottimetaken / percentdone) * percentremaining;
                      end
                      else timeremaining := 0;
                      sizgb := trim(trimleft(floattostr(percentdone))); x := pos('.',sizgb); if x > 0 then sizgb := copy(sizgb,1,x+2); sizgb := trim(trimleft(sizgb));
                      if percentdone >= 100 then
                       begin
                        StatusMemo.Lines.Add('Completed '+sizgb+'% so estimated time remaining is: 0:0:0. Total time taken: '+timetostr(tottimetaken)+'.');
                       end
                       else
                       begin
                        StatusMemo.Lines.Add('Completed '+sizgb+'% so estimated time remaining (H:M:S) is: '+timetostr(timeremaining)+' ('+datetimetostr(now+timeremaining)+').');
                       end;
                    end;
                  end;
                 inc(ct);
                end;
               StatusMemo.Lines.Add('Process complete.');
             finally
              doenablecontrols;
              Startbutton.Caption := 'Start';
              application.processmessages;
             end;
            end;
          end
          else showmessage('Please enter a valid "FFMpeg Parematers" command including "<source file>" and "<target file>"'+#13+
                           'e.g. ffmpeg -i "<source file>" -global_quality 22 "<target file>".');
        end
        else showmessage('Please select a valid Target Video Files Folder.');
      end
      else showmessage('Please select a valid Target Video Files Folder.');
    end;
  end;
end;

procedure Tbatchffpmegmainform.FormShow(Sender: TObject);
begin
 factive := false; // Disable all control events whilst setting the default configuration.
 SourceImageFileTypesEdit.text := '*.MKV;*.M4V;*.MP4;*.AVI;*.MOV;*.WMV;*.WEBM';
 presSourceImageFileTypesEditText := SourceImageFileTypesEdit.text;
 presSourceFolderEditText := '';
 TargetFileTypeComboBox.Items.Clear;
 TargetFileTypeComboBox.Items.Add('mkv');
 TargetFileTypeComboBox.Items.Add('mp4');
 TargetFileTypeComboBox.Items.Add('m4v');
 TargetFileTypeComboBox.Items.Add('avi');
 TargetFileTypeComboBox.Items.Add('mov');
 TargetFileTypeComboBox.Items.Add('wmv');
 TargetFileTypeComboBox.Items.Add('webm');
 TargetFileTypeComboBox.ItemIndex := 0;
 FFMpegParametersEdit.text := 'ffmpeg -i "<source file>" -global_quality 22 -init_hw_device vaapi=amd:/dev/dri/renderD129 -vf "format=nv12|vaapi,hwupload"  -c:v h264_vaapi "<target file>"';
 load_config;
 scanforfiles;
 StatusMemo.clear;
 StatusMemo.Lines.Add('Waiting. Please select the required source video files for conversion and then click "Start".'); // Should be good enough to tell them what to do.
 factive := true;
end;

procedure Tbatchffpmegmainform.FormClose(Sender: TObject;
 var CloseAction: TCloseAction);
begin
 save_config;
 CloseAction := caFree;
end;

end.

