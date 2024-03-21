using System.Runtime.InteropServices;
using UnityEngine;
using UnityEngine.UI;

public class ResourceTracker : MonoBehaviour
{
    [SerializeField] private Text textResult;

#if UNITY_IOS
    [DllImport("__Internal")]
    private static extern void _startTracking();

    [DllImport("__Internal")]
    private static extern string _stopTracking();
#endif

    public void StartTracking()
    {
#if UNITY_IOS && !UNITY_EDITOR
        _startTracking();
#else
        textResult.text = "iOS platform required";
#endif
    }
    
    public void StopTracking()
    {
#if UNITY_IOS && !UNITY_EDITOR       
        string output = _stopTracking();
        textResult.text = output.Replace(",", "\n");
#endif
    }
}
