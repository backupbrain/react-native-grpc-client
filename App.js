/**
 * Sample React Native App
 * https://github.com/facebook/react-native
 *
 * @format
 * @flow strict-local
 */

import React, { useRef, useState } from 'react';
import type {Node} from 'react';
import {
  SafeAreaView,
  ScrollView,
  StatusBar,
  StyleSheet,
  Text,
  useColorScheme,
  View,
  TextInput,
  Button,
} from 'react-native';

import {
  Colors,
  DebugInstructions,
  Header,
  LearnMoreLinks,
  ReloadInstructions,
} from 'react-native/Libraries/NewAppScreen';

import JsAuthClient from './utils/JsAuthClient';

const Section = ({children, title}): Node => {
  const isDarkMode = useColorScheme() === 'dark';
  
  return (
    <View style={styles.sectionContainer}>
    </View>
  );
};

const App: () => Node = () => {
  const isDarkMode = useColorScheme() === 'dark';

  const backgroundStyle = {
    backgroundColor: isDarkMode ? Colors.darker : Colors.lighter,
  };

  const [username, setUsername] = useState('email@example.com')
  const [password, setPassword] = useState('password')
  const [oauthToken, setOauthToken] = useState('')
  const jsAuthClient = useRef(new JsAuthClient())

  const login = async (username, password) => {
    try {
      const oauthData = await jsAuthClient.current.login(username, password)
      setOauthToken(oauthData.token)
    } catch (error) {
      console.log(error)
      console.log(error.message)
    }
    
  }
  const logout = async (oauthToken) => {
    await jsAuthClient.current.logout(oauthToken)
    setOauthToken('')
  }

  return (
    <SafeAreaView style={styles.backgroundStyle}>
      <TextInput
        type="email"
        placeholder="Email"
        autoCapitalize="none"
        value={username}
        onChangeText={setUsername}
        style={styles.textInput}
      />
      <TextInput
        type="password"
        placeholder="Password"
        autoCapitalize="none"
        value={password}
        onChangeText={setPassword}
        style={styles.textInput}
      />
      <Button
        title="Login"
        onPress={() => {
          login(username, password)
        }}
      />
      <Button
        title="Logout"
        onPress={() => {
          logout(oauthToken)
        }}
      />
      <Text>Oauth Token: {oauthToken}</Text>
    </SafeAreaView>
  );
};

const styles = StyleSheet.create({
  middleStyle: {
    justifyContent: 'center'
  },
  backgroundStyle: {
    height: '100%',
  },
  textInput: {
    borderWidth: 1,
    borderColor: '#ccc',
    padding: 12,
    marginBottom: 12,
    backgroundColor: '#fff'
  },
  sectionContainer: {
    marginTop: 32,
    paddingHorizontal: 24,
  },
  sectionTitle: {
    fontSize: 24,
    fontWeight: '600',
  },
  sectionDescription: {
    marginTop: 8,
    fontSize: 18,
    fontWeight: '400',
  },
  highlight: {
    fontWeight: '700',
  },
});

export default App;
