using UnityEngine;
using UnityEngine.InputSystem;

using Unity.XR.CoreUtils; // Needed for XROrigin

namespace AzureVR
{
    [DefaultExecutionOrder(-10)]
    public class XRLocomotionSetup : MonoBehaviour
    {
        [Header("Input Actions Asset")]
        public InputActionAsset locomotionActions;
        public string leftMap = "LeftHand";
        public string rightMap = "RightHand";

        [Header("Smooth Move")]
        public bool enableSmoothMove = true;
        public float moveSpeed = 2.0f;

        [Header("Snap Turn")]
        public bool enableSnapTurn = true;
        public float snapTurnAngle = 45f;
        public float snapCooldown = 0.4f;

    [Header("Smooth Turn (Head-Based)")]
    public bool enableSmoothTurn = false;
    public float smoothTurnSpeedDegPerSec = 90f; // degrees per second at full axis deflection
    public float smoothTurnDeadzone = 0.2f;

        [Header("Teleport")]
        public bool enableTeleport = true;
        public LayerMask teleportLayers = ~0;

        private XROrigin _origin;
        private CharacterController _cc;
        private InputAction _moveAction;
        private InputAction _snapAction;
        private InputAction _teleportActivate;
        private InputAction _teleportSelect;
        private float _lastSnapTime;
        private UnityEngine.XR.Interaction.Toolkit.Locomotion.Teleportation.TeleportationProvider _teleportProvider;
        private UnityEngine.XR.Interaction.Toolkit.Interactors.XRRayInteractor _teleRay;

        void Awake()
        {
            _origin = FindObjectOfType<XROrigin>();
            if (_origin == null)
            {
                Debug.LogWarning("XRLocomotionSetup: No XROrigin found.");
                enabled = false; return;
            }
            EnsureCharacterController();
            if (enableTeleport)
            {
                var teleGo = new GameObject("TeleportRay");
                teleGo.transform.SetParent(_origin.CameraFloorOffsetObject.transform, false);
                _teleRay = teleGo.AddComponent<UnityEngine.XR.Interaction.Toolkit.Interactors.XRRayInteractor>();
                _teleRay.rayOriginTransform = teleGo.transform;
                _teleRay.maxRaycastDistance = 10f;
                _teleRay.raycastMask = teleportLayers;
                _teleportProvider = _origin.gameObject.GetComponent<UnityEngine.XR.Interaction.Toolkit.Locomotion.Teleportation.TeleportationProvider>();
                if (_teleportProvider == null)
                    _teleportProvider = _origin.gameObject.AddComponent<UnityEngine.XR.Interaction.Toolkit.Locomotion.Teleportation.TeleportationProvider>();
            }
        }

        void OnEnable()
        {
            if (locomotionActions != null)
            {
                var lm = locomotionActions.FindActionMap(leftMap, true);
                var rm = locomotionActions.FindActionMap(rightMap, true);
                _moveAction = lm.FindAction("Move", true);
                _snapAction = rm.FindAction("SnapTurn", true);
                _teleportActivate = rm.FindAction("TeleportActivate", false);
                _teleportSelect = rm.FindAction("TeleportSelect", false);
                locomotionActions.Enable();
            }
        }

        void OnDisable()
        {
            locomotionActions?.Disable();
        }

        void Update()
        {
            if (enableSmoothMove) HandleSmoothMove();
            if (enableSnapTurn && !enableSmoothTurn) HandleSnapTurn();
            if (enableSmoothTurn) HandleSmoothTurn();
            if (enableTeleport) HandleTeleport();
        }

        private void HandleSmoothMove()
        {
            if (_moveAction == null) return;
            Vector2 axis = _moveAction.ReadValue<Vector2>();
            var headYaw = Quaternion.Euler(0, _origin.Camera.transform.eulerAngles.y, 0);
            Vector3 dir = headYaw * new Vector3(axis.x, 0, axis.y);
            Vector3 motion = dir * (moveSpeed * Time.deltaTime);
            _cc.Move(motion);
        }

        private void HandleSnapTurn()
        {
            if (_snapAction == null) return;
            Vector2 axis = _snapAction.ReadValue<Vector2>();
            if (Time.time - _lastSnapTime < snapCooldown) return;
            if (Mathf.Abs(axis.x) > 0.6f)
            {
                float angle = Mathf.Sign(axis.x) * snapTurnAngle;
                _origin.RotateAroundCameraUsingOriginUp(angle);
                _lastSnapTime = Time.time;
            }
        }

        private void HandleSmoothTurn()
        {
            if (_snapAction == null) return; // reusing right-hand axis
            Vector2 axis = _snapAction.ReadValue<Vector2>();
            float x = axis.x;
            if (Mathf.Abs(x) < smoothTurnDeadzone) return;
            float signedSpeed = x * smoothTurnSpeedDegPerSec * Time.deltaTime;
            _origin.RotateAroundCameraUsingOriginUp(signedSpeed);
        }

        private void HandleTeleport()
        {
            if (_teleRay == null || _teleportProvider == null) return;
            bool activating = _teleportActivate != null && _teleportActivate.IsPressed();
            if (!activating)
            {
                _teleRay.gameObject.SetActive(false);
                return;
            }
            _teleRay.gameObject.SetActive(true);
            if (_teleportSelect != null && _teleportSelect.triggered)
            {
                if (_teleRay.TryGetCurrent3DRaycastHit(out var hit))
                {
                    var request = new UnityEngine.XR.Interaction.Toolkit.Locomotion.Teleportation.TeleportRequest
                    {
                        destinationPosition = hit.point,
                        // Using WorldSpaceUp (other options: TargetUp, TargetUpAndForward, None)
                        matchOrientation = UnityEngine.XR.Interaction.Toolkit.Locomotion.Teleportation.MatchOrientation.WorldSpaceUp
                    };
                    _teleportProvider.QueueTeleportRequest(request);
                }
            }
        }

        private void EnsureCharacterController()
        {
            _cc = _origin.GetComponent<CharacterController>();
            if (_cc == null)
            {
                _cc = _origin.gameObject.AddComponent<CharacterController>();
                _cc.height = 1.8f;
                _cc.radius = 0.3f;
                _cc.center = new Vector3(0, _cc.height / 2f, 0);
            }
        }
    }
}
