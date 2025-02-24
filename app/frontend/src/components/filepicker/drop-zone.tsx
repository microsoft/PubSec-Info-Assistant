// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

import { array, func } from "prop-types";
import React, {useEffect, useRef} from "react";
import styles from "./drop-zone.module.css";

const Banner = ({ onClick, onDrop}: {onClick: any, onDrop: any, tabIndex: number}) => {
  const bannerRef = useRef<HTMLDivElement>(null);
  const handleDragOver = (ev: any) => {
    ev.preventDefault();
    ev.stopPropagation();
    ev.dataTransfer.dropEffect = "copy";
  };

  const handleDrop = (ev: any) => {
    ev.preventDefault();
    ev.stopPropagation();
    onDrop(ev.dataTransfer.files);
  };

  const handleKeyDown = (e: KeyboardEvent) => {
    if ((e.key === " " || e.key === "Enter" || e.key === "Spacebar") ) {
      onClick();
    }
  };

  useEffect(() => {
    const banner = bannerRef.current;
    if (banner) {
      banner.addEventListener('keydown', handleKeyDown);
    }
    return () => {
      if (banner) {
        banner.removeEventListener('keydown', handleKeyDown);
      }
    };
  }, []);

  return (
    <div
      ref={bannerRef}
      className={styles.banner}
      onClick={onClick}
      onDragOver={handleDragOver}
      onDrop={handleDrop}
      tabIndex={0} // Make the div focusable
      role="button"
    >
      <span className={styles.banner_text}>Click to Add files</span>
      <span className={styles.banner_text}>Or</span>
      <span className={styles.banner_text}>Drag and Drop files here</span>
    </div>
  );
};

const DropZone = ({ onChange, accept = ["*"] }: {onChange: any, accept: string[]}) => {
  const inputRef = React.useRef<HTMLInputElement>(null);

  const handleClick = () => {
    inputRef.current?.click();
  };

  const handleChange = (ev: any) => {
    onChange(ev.target.files);
  };

  const handleDrop = (files: any) => {
    onChange(files);
  };

  

  return (
    <div className={styles.wrapper} >
      <Banner onClick={handleClick} onDrop={handleDrop}  tabIndex={0}/>
      <input
        type="file"
        aria-label="add files"
        className={styles.input}
        ref={inputRef}
        multiple={true}
        onChange={handleChange}
        accept={accept.join(",")}
      />
    </div>
  );
};

DropZone.propTypes = {
  accept: array,
  onChange: func,
};

export { DropZone };
