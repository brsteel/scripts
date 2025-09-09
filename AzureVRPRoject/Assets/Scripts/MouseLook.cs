using UnityEngine;

namespace AzureVR
{
    /// <summary>
    /// Simple mouse look for desktop VR testing when headset isn't available
    /// </summary>
    public class MouseLook : MonoBehaviour
    {
        public float mouseSensitivity = 100f;
        public float moveSpeed = 5f;
        
        private float xRotation = 0f;
        private CharacterController controller;

        void Start()
        {
            // Lock cursor to center of screen for better mouse look
            Cursor.lockState = CursorLockMode.Locked;
            
            // Add character controller for movement
            controller = gameObject.AddComponent<CharacterController>();
            controller.height = 1.8f;
            controller.radius = 0.3f;
        }

        void Update()
        {
            HandleMouseLook();
            HandleMovement();
            
            // Press Escape to unlock cursor
            if (Input.GetKeyDown(KeyCode.Escape))
            {
                Cursor.lockState = Cursor.lockState == CursorLockMode.Locked ? 
                    CursorLockMode.None : CursorLockMode.Locked;
            }
        }

        void HandleMouseLook()
        {
            if (Cursor.lockState != CursorLockMode.Locked) return;
            
            float mouseX = Input.GetAxis("Mouse X") * mouseSensitivity * Time.deltaTime;
            float mouseY = Input.GetAxis("Mouse Y") * mouseSensitivity * Time.deltaTime;

            xRotation -= mouseY;
            xRotation = Mathf.Clamp(xRotation, -90f, 90f);

            transform.localRotation = Quaternion.Euler(xRotation, 0f, 0f);
            transform.parent.Rotate(Vector3.up * mouseX);
        }

        void HandleMovement()
        {
            float x = Input.GetAxis("Horizontal");
            float z = Input.GetAxis("Vertical");

            Vector3 move = transform.right * x + transform.forward * z;
            controller.Move(move * moveSpeed * Time.deltaTime);
            
            // Simple gravity
            controller.Move(Vector3.down * 9.81f * Time.deltaTime);
        }
    }
}
