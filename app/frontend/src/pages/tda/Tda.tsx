// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

import { BlobServiceClient } from "@azure/storage-blob";
import { CheckboxVisibility, DetailsList, DetailsListLayoutMode, IColumn, mergeStyles } from '@fluentui/react';
import classNames from "classnames";
import { nanoid } from "nanoid";
import { ReactNode, useCallback, useEffect, useMemo, useState } from "react";
import { DropZone } from "./drop-zone"
import styles from "./file-picker.module.css";
import { FilesList } from "./files-list";
import cstyle from "./Tda.module.css" 
import Papa from "papaparse";
import { postCsv, processCsvAgentResponse, getCsvAnalysis, getCharts, refresh } from "../../api";
import { Accordion, Card, Button } from 'react-bootstrap';
import ReactMarkdown from "react-markdown";


interface Props {
  folderPath: string;
  tags: string[];
}

const Tda = ({folderPath, tags}: Props) => {
  const [files, setFiles] = useState<any>([]);
  const [progress, setProgress] = useState(0);
  const [uploadStarted, setUploadStarted] = useState(false);
  const folderName = folderPath;
  const tagList = tags;
  const [fileUploaded, setFileUploaded] = useState(false);
  const [output, setOutput] = useState('');
  const [otherq, setOtherq] = useState('');
  const [selectedQuery, setSelectedQuery] = useState('How many rows are there?');
  const [dataFrame, setDataFrame] = useState<object[]>([]);
  const [loading, setLoading] = useState(false);
  const [inputValue, setInputValue] = useState("");
  const [base64Images, setBase64Images] = useState<string[]>([]);
  const [fileu, setFile] = useState<File | null>(null);

  




  const setOtherQ = (selectedQuery: string) => {
    if (selectedQuery === "other") {
      return inputValue;
    }
    return selectedQuery;
  };

  const handleAnalysis = async () => {
    const retries: number = 3;
    setOutput('');
    setLoading(true);
    let lastError;
  
    for (let i = 0; i < retries; i++) {
      try {
        const query = setOtherQ(selectedQuery);
        if (fileu) {
          const solve = await getCsvAnalysis(query, fileu);
          let outputString = '';
          solve.forEach((item) => {
            outputString += item + '\n';
            console.log(item);
          });
          setLoading(false);
          setOutput(outputString);
          const charts = await getCharts();
          setImages(charts.map((chart: String) => chart.toString()));
          return;  // If everything is successful, return from the function
        } else {
          setOutput("no file has been uploaded.")
          setLoading(false);
          return;
        }
      } catch (error) {
        lastError = error;
      }
    }
  
    // If the code reaches here, all retries have failed. Handle the error as needed.
    console.error(lastError);
    setLoading(false);
    setOutput('An error occurred.');
  };

  useEffect(() => {
    const handleRefresh = async () => {
      // Call your method here
      await refresh();
    };

    handleRefresh();

    // Cleanup function
    return () => {
      // This function will be called when the component unmounts
      // You can call another method here if needed
    };
  }, []);

  const handleAnswer = async () => {
    const retries: number = 3;
    for (let i = 0; i < retries; i++) {
      try {
        const query = setOtherQ(selectedQuery);
        setOutput('');
        setLoading(true);
        if (fileu) {
          const result = await processCsvAgentResponse(query, fileu);
          setLoading(false);
          setOutput(result.toString());
          const charts = await getCharts();
          setImages(charts.map((chart: String) => chart.toString()));
        }
        else {
          setOutput("no file file has been uploaded.")
          setLoading(false);
        }
    } catch (error) {
    lastError = error;
    }
  // If the code reaches here, all retries have failed. Handle the error as needed.
    console.error(lastError);
    setLoading(false);
    setOutput('An error occurred.');
  };

  // handler called when files are selected via the Dropzone component

  const handleQueryChange = (event: { target: { value: any; }; }) => {
    const query = event.target.value;
    setSelectedQuery(query);
    // Handle the selected query here
  };
  
  const handleOnChange = useCallback((files: any) => {
    let filesArray = Array.from(files);
  
    filesArray = filesArray.filter((file: any) => file.type === 'text/csv');
  
    filesArray = filesArray.map((file: any) => ({
      id: nanoid(),
      file
    }));
  
    setFiles(filesArray as any);
    setProgress(0);
    setUploadStarted(false);
  }, []);

  // handle for removing files form the files list view
  const handleClearFile = useCallback((id: any) => {
    setFiles((prev: any) => prev.filter((file: any) => file.id !== id));
  }, []);

  // whether to show the progress bar or not
  const canShowProgress = useMemo(() => files.length > 0, [files.length]);

  // execute the upload operation
  const handleUpload = useCallback(async () => {
    try {
      setFile(null);
      const data = new FormData();
      console.log("files", files);
      setUploadStarted(true);
      files.forEach(async (indexedFile: any) => {  
          var file = indexedFile.file as File;
            Papa.parse(file, {
              header: true,
              dynamicTyping: true,
              complete: async function(results) {
                data.append("file", file);
                console.log("Finished:", results.data);
                // Here, results.data is your dataframe
                // You can set it in your state like this:
                setDataFrame(results.data as object[]);
                try {               
                  const response = await postCsv(file).then((response) => {
                    setProgress(100);
                    setFileUploaded(true);
                    console.log('Response from server:', response);
                  }).catch((error) => {console.log(error);}); 
                  
                } catch (error) {
                  console.error('Error posting CSV:', error);
                }
              }
            });
            setFile(file)
      });
    } catch (error) {
      console.error('Error uploading files: ', error);
    }
  }, [files]);

// set progress to zero when there are no files
  useEffect(() => {
    if (files.length < 1) {
      setProgress(0);
    }
  }, [files.length]);

  // set uploadStarted to false when the upload is complete
  useEffect(() => {
    if (progress === 100) {
      setUploadStarted(false);
    }
  }, [progress]);

  let indexLength = 0;
if (dataFrame.length > 0) {
  for (let i = 0; i < dataFrame.length; i++) {
    const length = String(i).length;
    if (length > indexLength) {
      indexLength = length;
    }
  }
}
 

  const columnLengths: { [key: string]: number } = dataFrame.reduce((lengths: { [key: string]: number }, row: Record<string, any>) => {
    Object.keys(row).forEach((key) => {
      const valueLength = Math.max(String(row[key]).length, key.length);
      if (!lengths[key] || valueLength > lengths[key]) {
        lengths[key] = valueLength;
      }
    });
    return lengths;
  }, Object.keys(dataFrame[0] || {}).reduce((lengths: { [key: string]: number }, key: string) => {
    lengths[key] = key.length;
    return lengths;
  }, {} as { [key: string]: number }));
  const columns: IColumn[] = [
    {
      key: 'index',
      name: '',
      fieldName: 'index',
      minWidth: indexLength * 8,
      maxWidth: indexLength * 8,
      isResizable: true,
    },
    // Add more columns dynamically based on the dataFrame
    ...Object.keys(dataFrame[0] || {}).map((key) => ({
      key,
      name: key,
      fieldName: key,
      minWidth: columnLengths[key] * 8,
      maxWidth: columnLengths[key] * 8,
      isResizable: true,
    })),
  ];
  
  const items = dataFrame.map((row, index) => ({ index, ...row }));

  const uploadComplete = useMemo(() => progress === 100, [progress]);

  const setImages = (newBase64Strings: string[]) => {
    setBase64Images(newBase64Strings);
  };
  return (<div>
    <div className={cstyle.centeredContainer}>
      <p>Upload a CSV file</p>
    
    <div className={styles.wrapper}>
      
      {/* canvas */}
      <div className={styles.canvas_wrapper}>
        <DropZone onChange={handleOnChange} accept={files} />
      </div>

      {/* files listing */}
      {files.length ? (
        <div className={styles.files_list_wrapper}>
          <FilesList
            files={files}
            onClear={handleClearFile}
            uploadComplete={uploadComplete}
          />
        </div>
      ) : null}

      {/* progress bar */}
      {canShowProgress ? (
        <div className={styles.files_list_progress_wrapper}>
          <progress value={progress} max={100} style={{ width: "100%" }} />
        </div>
      ) : null}

      {/* upload button */}
      {files.length ? (
        <button
          onClick={handleUpload}
          className={classNames(
            styles.upload_button,
            uploadComplete || uploadStarted ? styles.disabled : ""
          )}
          aria-label="upload files"
        >
          {`Upload ${files.length} Files`}
        </button>
      ) : null}
    </div>
    <div>
      <p>Select an example query:</p>
      <select className={cstyle.inputField} onChange={handleQueryChange} style={{ width: "100%" }}>
        <option value="rows">How many rows are there?</option>
        <option value="dataType">What is the data type of each column?</option>
        <option value="summaryStats">What are the summary statistics for categorical data?</option>
        <option value="other">Other</option>
    </select>
  {selectedQuery === 'other' && (
    <div >
    <p>Ask a question about your CSV:</p>
    <input
      className={cstyle.inputField}
      type="text"
      placeholder="Enter your query"
      value={inputValue}
      onChange={(e) => setInputValue(e.target.value)}
    />
      </div>
      
    )}
      </div>
      
      
    </div>
    <h1>Ouput</h1>
    <div className={cstyle.centeredContainer}>
    <details style={{ width: '100%' }}>
  <summary>See Dataframe</summary>
  <div style={{ width: '100%', height: '500px', overflow: 'auto', direction: 'rtl'  }}>
  <div style={{ direction: 'ltr' }}>
  <DetailsList
  items={items}
  className={cstyle.mydetailslist}
  columns={columns}
  setKey="set"
  layoutMode={DetailsListLayoutMode.justified}
  selectionPreservedOnEmptyClick={true}
  checkboxVisibility={CheckboxVisibility.hidden}
/>
</div>
  </div>
</details>
    </div>
  <div className={cstyle.centeredContainer}>
    <div className={cstyle.buttonContainer}>
    <Button variant="secondary" onClick={handleAnalysis}>Here is my analysis</Button>
    <Button variant="secondary" onClick={handleAnswer}>Show me the answer</Button>
    </div>
    {loading && <div className="spinner">Loading...</div>}
    { output && (
      <div style={{width: '100%'}}>
        <h2>Tabular Data Assistant Response:</h2>
        <ReactMarkdown>{output}</ReactMarkdown>
        <p>Generated images</p>
        {base64Images.length > 0 ? (
      base64Images.map((base64Image, index) => (
        <img style={{ width: '100%' }} key={index} src={`data:image/png;base64,${base64Image}`} alt={`Chart ${index}`} />
      ))
    ) : (
      <p>No images generated</p>
    )}
      </div>
    )}
</div>

</div>
  );
};

export { Tda };
