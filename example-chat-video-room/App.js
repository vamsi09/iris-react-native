import React from 'react';
import LoginScreen from './components/Login.js'
import LoginView from './components/LoginView.js'
import RoomSelection from './components/RoomSelection.js'
import AnonymousRoomSelection from './components/AnonymousRoomSelection.js'
import RoomView from './components/RoomView.js'

import {
  StackNavigator,
} from 'react-navigation';

/**
 * 3 screen in the app, one for login, one for room selection and one for chat/video call view
 */
const AppNavigator = StackNavigator({
  Home: { screen: LoginView },
  RoomSelection: { screen: RoomSelection },
  RoomView: { screen: RoomView }
});




export default class App extends React.Component {
  constructor(props) {
      super(props);
      this.state = {AppNavigator: ''}
  }
   getCurrentRouteName(navigationState) {
    if (!navigationState) {
      return null;
    }
    const route = navigationState.routes[navigationState.index];
    // dive into nested navigators
    if (route.routes) {
      return getCurrentRouteName(route);
    }
    return route.routeName;
  }
  render() {
      return (
        <AppNavigator
        onNavigationStateChange={(prevState, currentState) => {
          const currentScreen = this.getCurrentRouteName(currentState);
          const prevScreen = this.getCurrentRouteName(prevState);
    
          if (prevScreen !== currentScreen) {
            this.setState({AppNavigator: currentScreen})
          }
        }}
        screenProps={{currentScreen: this.state.AppNavigator}}
      />
      );
  }
}