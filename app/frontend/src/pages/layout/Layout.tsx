// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

import { Outlet, NavLink, Link } from "react-router-dom";
import openai from "../../assets/openai.svg";
import { WarningBanner } from "../../components/WarningBanner/WarningBanner";
import styles from "./Layout.module.css";
import { Title } from "../../components/Title/Title";
import { getFeatureFlags, GetFeatureFlagsResponse } from "../../api";
import { useEffect, useState } from "react";

export const Layout = () => {
    const [featureFlags, setFeatureFlags] = useState<GetFeatureFlagsResponse | null>(null);

    async function fetchFeatureFlags() {
        try {
            const fetchedFeatureFlags = await getFeatureFlags();
            setFeatureFlags(fetchedFeatureFlags);
        } catch (error) {
            // Handle the error here
            console.log(error);
        }
    }

    useEffect(() => {
        fetchFeatureFlags();
    }, []);

    return (
        <div className={styles.layout}>
            <header className={styles.header} role={"banner"}>
                <WarningBanner />
                <div className={styles.headerContainer}>
                    <div className={styles.headerTitleContainer}>
                        <img src={openai} alt="Azure OpenAI" className={styles.headerLogo} />
                        <h3 className={styles.headerTitle}><Title /></h3>
                    </div>
                    <nav>
                        <ul className={styles.headerNavList}>
                            <li>
                                <NavLink to="/" className={({ isActive }) => (isActive ? styles.headerNavPageLinkActive : styles.headerNavPageLink)}>
                                    Chat
                                </NavLink>
                            </li>
                            <li className={styles.headerNavLeftMargin}>
                                <NavLink to="/content" className={({ isActive }) => (isActive ? styles.headerNavPageLinkActive : styles.headerNavPageLink)}>
                                    Manage Content
                                </NavLink>
                            </li>
                            {featureFlags?.ENABLE_MATH_ASSISTANT &&
                                <li className={styles.headerNavLeftMargin}>
                                    <NavLink to="/tutor" className={({ isActive }) => (isActive ? styles.headerNavPageLinkActive : styles.headerNavPageLink)}>
                                    Math Assistant
                                    <br />  
                                    (preview)
                                    </NavLink>
                                </li>
                            }
                            {featureFlags?.ENABLE_TABULAR_DATA_ASSISTANT &&
                                <li className={styles.headerNavLeftMargin}>
                                    <NavLink to="/tda" className={({ isActive }) => (isActive ? styles.headerNavPageLinkActive : styles.headerNavPageLink)}>
                                    Tabular Data Assistant
                                    <br />  
                                    (preview)
                                    </NavLink>
                                    
                                      
                                </li>
                            }
                    </ul>
                    </nav>
                </div>
            </header>

            <Outlet />

            <footer>
                <WarningBanner />
            </footer>
        </div>
    );
};
