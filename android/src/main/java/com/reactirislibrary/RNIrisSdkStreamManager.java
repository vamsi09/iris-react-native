package com.reactirislibrary;

/**
 * Created by Manish Ganvir on 1/18/18.
 */
import com.comcast.irisrtcsdk.IrisRtcSdk.IrisRtcMediaTrack;
import org.webrtc.EglBase;
import java.util.HashMap;

public class RNIrisSdkStreamManager {
    private static RNIrisSdkStreamManager streamManager;
    private static EglBase rootEglBase;
    private static  HashMap<String,IrisRtcMediaTrack>streamInfo;

    /**
     * A Method to get the instance of this class
     *
     *
     */
    public static RNIrisSdkStreamManager getInstance() {
        if (streamManager == null) {
            streamManager = new RNIrisSdkStreamManager();
            rootEglBase = EglBase.create();
            streamInfo = new HashMap<String,IrisRtcMediaTrack>();
        }

        return streamManager;
    }

    public EglBase getEglBase(){
        return rootEglBase;
    }


    public void addTrack(IrisRtcMediaTrack track, String trackId){
        streamInfo.put(trackId,track);
    }

    public IrisRtcMediaTrack getTrack( String trackId){
        return streamInfo.get(trackId);
    }
    public IrisRtcMediaTrack removeTrack( String trackId){
        return streamInfo.remove(trackId);
    }
}
