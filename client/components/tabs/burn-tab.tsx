import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from "@/components/ui/card";
import Icons from "@/components/icons";
import { WithdrawForm } from "@/components/forms/withdraw-form";

export default function BurnTab() {
  return (
    <div className="grid gap-2 grid-cols-1">
      <Card className="w-full">
        <CardHeader className="space-y-0">
          <CardDescription>Minted </CardDescription>
          <CardTitle className="text-4xl tabular-nums">
            12,584{" "}
            <div className="flex flex-row space-x-2 items-center">
              <Icons.bs width={25} height={25} />
              <span className="font-sans text-sm font-normal tracking-normal text-muted-foreground">
                BOBC
              </span>
            </div>
          </CardTitle>
        </CardHeader>
      </Card>
      <Card>
        <CardHeader>
          <CardTitle>Burn</CardTitle>
          <CardDescription>
            The amount of BOBC that your are going to burn.
          </CardDescription>
        </CardHeader>
        <CardContent className="space-y-2">
          <WithdrawForm />
        </CardContent>
      </Card>
    </div>
  );
}
