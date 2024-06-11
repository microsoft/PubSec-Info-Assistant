// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

import { Outlet, NavLink, Link } from "react-router-dom";
import logo from "../../assets/full-logo.png";
import { WarningBanner } from "../../components/WarningBanner/WarningBanner";
import styles from "./Layout.module.css";
import { Title } from "../../components/Title/Title";
import { getFeatureFlags, GetFeatureFlagsResponse } from "../../api";
import { useEffect, useState } from "react";
import { Chat48Regular, ChatMultiple24Regular, ChatMultiple32Regular, ChatMultipleRegular, ContentSettings32Regular, MathFormatProfessionalFilled, MathFormatProfessionalRegular, TableSearchFilled, TableSearchRegular } from "@fluentui/react-icons";

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
                <div className={styles.headerContainer}>
                    <div className={styles.headerTitleContainer}>
                        <img src={logo} alt="U.S. Department of HHS" className={styles.headerLogo} />
                    </div>
                </div>

            </header>
            <nav className={styles.nav}>
                <div className={styles.navLogo}>
                    <Title />
                </div>
                <ul className={styles.headerNavList}>
                    <li>
                        <NavLink to="/" className={({ isActive }) => (isActive ? styles.headerNavPageLinkActive : styles.headerNavPageLink)}>
                            <ChatMultiple32Regular />
                            Chat
                        </NavLink>
                    </li>
                    <li className={styles.headerNavLeftMargin}>
                        <NavLink to="/content" className={({ isActive }) => (isActive ? styles.headerNavPageLinkActive : styles.headerNavPageLink)}>
                            <ContentSettings32Regular />
                            Manage Content
                        </NavLink>
                    </li>
                    {featureFlags?.ENABLE_MATH_ASSISTANT &&
                        <li className={styles.headerNavLeftMargin}>
                            <NavLink to="/tutor" className={({ isActive }) => (isActive ? styles.headerNavPageLinkActive : styles.headerNavPageLink)}>
                                <MathFormatProfessionalRegular fontSize={'2em'} />
                                Math Assistant
                            </NavLink>
                        </li>
                    }
                    {featureFlags?.ENABLE_TABULAR_DATA_ASSISTANT &&
                        <li className={styles.headerNavLeftMargin}>
                            <NavLink to="/tda" className={({ isActive }) => (isActive ? styles.headerNavPageLinkActive : styles.headerNavPageLink)}>
                                <TableSearchRegular fontSize={'2em'} />
                                Tabular Data Assistant
                            </NavLink>


                        </li>
                    }
                </ul>
            </nav>
            <div className={styles.contentContainer}>
            <Outlet />
            </div>
            <footer className={styles.footer}>
                <WarningBanner />
            </footer>
        </div>
    );
};
