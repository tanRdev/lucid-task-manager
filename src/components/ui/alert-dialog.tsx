import * as AlertDialogPrimitive from "@radix-ui/react-alert-dialog";
import * as React from "react";

const AlertDialog = AlertDialogPrimitive.Root;

const AlertDialogTrigger = AlertDialogPrimitive.Trigger;

const AlertDialogPortal = AlertDialogPrimitive.Portal;

const AlertDialogOverlay = React.forwardRef<
  React.ElementRef<typeof AlertDialogPrimitive.Overlay>,
  React.ComponentPropsWithoutRef<typeof AlertDialogPrimitive.Overlay>
>(({ className, style, ...props }, ref) => (
  <AlertDialogPrimitive.Overlay
    className={className}
    style={{
      position: "fixed",
      inset: 0,
      zIndex: 50,
      backgroundColor: "rgba(0, 0, 0, 0.75)",
      backdropFilter: "blur(12px)",
      ...style,
    }}
    {...props}
    ref={ref}
  />
));
AlertDialogOverlay.displayName = AlertDialogPrimitive.Overlay.displayName;

const AlertDialogContent = React.forwardRef<
  React.ElementRef<typeof AlertDialogPrimitive.Content>,
  React.ComponentPropsWithoutRef<typeof AlertDialogPrimitive.Content>
>(({ className, style, ...props }, ref) => (
  <AlertDialogPortal>
    <AlertDialogOverlay />
    <AlertDialogPrimitive.Content
      ref={ref}
      className={className}
      style={{
        position: "fixed",
        left: "50%",
        top: "50%",
        zIndex: 50,
        transform: "translate(-50%, -50%)",
        width: "90%",
        maxWidth: "480px",
        background: "#111113",
        border: "1px solid #2A2A2E",
        borderRadius: "16px",
        padding: "32px",
        boxShadow:
          "0 25px 70px rgba(0, 0, 0, 0.7), 0 0 0 1px rgba(255, 255, 255, 0.03)",
        ...style,
      }}
      {...props}
    />
  </AlertDialogPortal>
));
AlertDialogContent.displayName = AlertDialogPrimitive.Content.displayName;

const AlertDialogHeader = ({
  className,
  style,
  ...props
}: React.HTMLAttributes<HTMLDivElement>) => (
  <div
    className={className}
    style={{
      display: "flex",
      flexDirection: "column",
      gap: "12px",
      marginBottom: "24px",
      ...style,
    }}
    {...props}
  />
);
AlertDialogHeader.displayName = "AlertDialogHeader";

const AlertDialogFooter = ({
  className,
  style,
  ...props
}: React.HTMLAttributes<HTMLDivElement>) => (
  <div
    className={className}
    style={{
      display: "flex",
      flexDirection: "row",
      justifyContent: "flex-end",
      gap: "12px",
      marginTop: "28px",
      ...style,
    }}
    {...props}
  />
);
AlertDialogFooter.displayName = "AlertDialogFooter";

const AlertDialogTitle = React.forwardRef<
  React.ElementRef<typeof AlertDialogPrimitive.Title>,
  React.ComponentPropsWithoutRef<typeof AlertDialogPrimitive.Title>
>(({ className, style, ...props }, ref) => (
  <AlertDialogPrimitive.Title
    ref={ref}
    className={className}
    style={{
      fontFamily: "Geist, sans-serif",
      fontSize: "20px",
      fontWeight: 600,
      color: "#FFFFFF",
      lineHeight: 1.3,
      ...style,
    }}
    {...props}
  />
));
AlertDialogTitle.displayName = AlertDialogPrimitive.Title.displayName;

const AlertDialogDescription = React.forwardRef<
  React.ElementRef<typeof AlertDialogPrimitive.Description>,
  React.ComponentPropsWithoutRef<typeof AlertDialogPrimitive.Description>
>(({ className, style, ...props }, ref) => (
  <AlertDialogPrimitive.Description
    ref={ref}
    className={className}
    style={{
      fontFamily: "Geist, sans-serif",
      fontSize: "14px",
      color: "#ADADB0",
      lineHeight: 1.6,
      ...style,
    }}
    {...props}
  />
));
AlertDialogDescription.displayName =
  AlertDialogPrimitive.Description.displayName;

const AlertDialogAction = React.forwardRef<
  React.ElementRef<typeof AlertDialogPrimitive.Action>,
  React.ComponentPropsWithoutRef<typeof AlertDialogPrimitive.Action>
>(({ className, style, ...props }, ref) => {
  const [isHovered, setIsHovered] = React.useState(false);

  return (
    <AlertDialogPrimitive.Action
      ref={ref}
      className={className}
      style={{
        display: "inline-flex",
        alignItems: "center",
        justifyContent: "center",
        borderRadius: "10px",
        fontSize: "14px",
        fontWeight: 500,
        fontFamily: "Geist, sans-serif",
        height: "44px",
        paddingLeft: "24px",
        paddingRight: "24px",
        background: isHovered ? "#DC2626" : "#EF4444",
        color: "#FFFFFF",
        border: "none",
        cursor: "pointer",
        transition: "all 200ms cubic-bezier(0.16, 1, 0.3, 1)",
        outline: "none",
        boxShadow: isHovered
          ? "0 0 0 4px rgba(239, 68, 68, 0.15), 0 4px 12px rgba(239, 68, 68, 0.3)"
          : "0 2px 8px rgba(0, 0, 0, 0.3)",
        ...style,
      }}
      onMouseEnter={() => setIsHovered(true)}
      onMouseLeave={() => setIsHovered(false)}
      {...props}
    />
  );
});
AlertDialogAction.displayName = AlertDialogPrimitive.Action.displayName;

const AlertDialogCancel = React.forwardRef<
  React.ElementRef<typeof AlertDialogPrimitive.Cancel>,
  React.ComponentPropsWithoutRef<typeof AlertDialogPrimitive.Cancel>
>(({ className, style, ...props }, ref) => {
  const [isHovered, setIsHovered] = React.useState(false);

  return (
    <AlertDialogPrimitive.Cancel
      ref={ref}
      className={className}
      style={{
        display: "inline-flex",
        alignItems: "center",
        justifyContent: "center",
        borderRadius: "10px",
        fontSize: "14px",
        fontWeight: 500,
        fontFamily: "Geist, sans-serif",
        height: "44px",
        paddingLeft: "24px",
        paddingRight: "24px",
        background: isHovered ? "#2A2A2E" : "#1A1A1D",
        color: "#FFFFFF",
        border: `1px solid ${isHovered ? "#3A3A3E" : "#2A2A2E"}`,
        cursor: "pointer",
        transition: "all 200ms cubic-bezier(0.16, 1, 0.3, 1)",
        outline: "none",
        ...style,
      }}
      onMouseEnter={() => setIsHovered(true)}
      onMouseLeave={() => setIsHovered(false)}
      {...props}
    />
  );
});
AlertDialogCancel.displayName = AlertDialogPrimitive.Cancel.displayName;

export {
  AlertDialog,
  AlertDialogAction,
  AlertDialogCancel,
  AlertDialogContent,
  AlertDialogDescription,
  AlertDialogFooter,
  AlertDialogHeader,
  AlertDialogOverlay,
  AlertDialogPortal,
  AlertDialogTitle,
  AlertDialogTrigger,
};
