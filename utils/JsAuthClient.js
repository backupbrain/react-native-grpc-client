import { NativeModules } from "react-native"
const { AuthClient } = NativeModules

export default class JsAuthClient {
    constructor () {
        this.nativeAuthClient = AuthClient
        this.nativeAuthClient.init()
    }
    async login (username, password) {
        return this.nativeAuthClient.login(username, password)
    }
    async logout (oauthToken) {
        return this.nativeAuthClient.logout(oauthToken)
    }
}